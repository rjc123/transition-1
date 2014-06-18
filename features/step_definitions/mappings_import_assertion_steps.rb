Then(/^I should see how many of each type of mapping will be created$/) do
  steps %{
    Then I should see "Create 1 new redirect"
    Then I should see "Create 1 new archive"
    Then I should see "Create 1 new unresolved mapping"
  }
end

Then(/^I should see a preview of my mappings$/) do
  steps %{
    Then I should see "Preview mappings (3)"
  }
  within 'table.mappings tbody' do
    expect(page).to have_selector('tr:nth-child(1) td.mapping-type-redirect', text: 'Redirect')
    expect(page).to have_selector('tr:nth-child(2) td.mapping-type-archive', text: 'Archive')
    expect(page).to have_selector('tr:nth-child(3) td.mapping-type-unresolved', text: 'Archive')

    expect(page).to have_selector('tr:nth-child(1) td:last-child', text: '/redirect-me')
    expect(page).to have_selector('tr:nth-child(1) td:last-child', text: 'will redirect to https://www.gov.uk/new')
    expect(page).to have_selector('tr:nth-child(2) td:last-child', text: '/archive-me')
    expect(page).to have_selector('tr:nth-child(3) td:last-child', text: '/i-dont-know-what-i-am')
  end
end
