(function () {
  "use strict"
  var root = this,
      $ = root.jQuery;

  if (typeof root.GOVUK === 'undefined') {
    root.GOVUK = {};
  }

  root.GOVUK.Tagging = {
    ready: function () {
      $('.js-tag-list').select2({
        tags: true,
        initSelection: function (input, setTags) {
          setTags(
            $(input.val().split(",")).map(function () {
              return {
                id: this.trim(),
                text: this.trim()
              };
            })
          )
        }
      })
    }
  };
}).call(this);
