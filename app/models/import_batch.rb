require 'csv'

class ImportBatch < MappingsBatch
  attr_accessor :raw_csv
  attr_accessible :raw_csv

  def self.columns
    # Disable columns which are not used in this subclass
    super().reject { |column| ['type', 'new_url'].include?(column.name) }
  end

  has_many :entries, foreign_key: :mappings_batch_id, class_name: 'ImportBatchEntry', dependent: :delete_all

  validates :raw_csv, presence: { :if => :new_record?, message: I18n.t('mappings.import.raw_csv_empty') } # we only care about raw_csv at create-time
  validates :old_urls, old_urls_are_for_site: true
  validates :canonical_paths, presence: { :if => :new_record?, message: I18n.t('mappings.paths_empty') }
  validates :new_urls, each_in_collection: { validator: LengthValidator, maximum: (64.kilobytes - 1), message: I18n.t('mappings.new_url_too_long') }
  validates :new_urls, each_in_collection: { validator: NonBlankURLValidator, message: I18n.t('mappings.import.new_url_invalid') }
  validates :new_urls, each_in_collection: { validator: HostInWhitelistValidator, message: I18n.t('mappings.bulk.new_url_must_be_on_whitelist', email: Rails.configuration.support_email) }

  after_create :create_entries

  def create_entries
    canonical_path_hashes = deduplicated_csv_rows.map { |row| Digest::SHA1.hexdigest(row.path) }
    existing_mappings = site.mappings.where(path_hash: canonical_path_hashes)

    deduplicated_csv_rows.each do |row|
      entry = ImportBatchEntry.new(path: row.path, type: row.type, new_url: row.new_url)
      entry.mappings_batch = self
      path_hash = Digest::SHA1.hexdigest(row.path)
      entry.mapping = existing_mappings.detect { |mapping| mapping.path_hash == path_hash }
      entry.save!
    end
  end

  def old_urls
    deduplicated_csv_rows.map(&:old_value)
  end

  def new_urls
    deduplicated_csv_rows.select(&:redirect?).map(&:new_url)
  end

  def canonical_paths
    deduplicated_csv_rows.map(&:path)
  end

private
  def deduplicated_csv_rows
    @_deduplicated_csv_rows ||= begin
      return [] if raw_csv.blank?

      rows_by_path = {}
      CSV.parse(raw_csv).each_with_index do |csv_row, index|
        line_number = index + 1
        row = Transition::ImportBatchRow.new(site, line_number, csv_row)
        next unless row.data_row?
        next if row.homepage?

        # If we don't yet have a row for this canonical path, or if the row we're
        # considering is 'better' than the one we have already, put this row into
        # the hash.
        # The second expression here calls the `<=>` method on ImportBatchRow,
        # which knows which of two mappings is 'better'
        if !rows_by_path.has_key?(row.path) || row > rows_by_path[row.path]
          rows_by_path[row.path] = row
        end
      end
      rows_by_path.values
    end
  end
end
