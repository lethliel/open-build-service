function highlightSelectedFilters() {
  var filters = $('#content-selector-filters .accordion .accordion-item');
  filters.each(function() {
    var currentFilter = $(this);
    var selectedContentWrapper = currentFilter.find('.selected-content');
    if (selectedContentWrapper.length > 0) {
      var anySelected = [];
      $(this).find('input').each(function() {
        if ($(this).is(':checked')) {
          anySelected.push($(this).next('label').html());
        }
      });
      if (anySelected.length > 0) {
        currentFilter.find('.selected-content').html(anySelected.join(', '));
      }
      else {
        currentFilter.find('.selected-content').text("");
      }
    }
  });
}
function submitFilters() {
  $('#content-selector-filters-form').submit();
  $('#content-selector-filters input').attr('disabled', 'disabled');
  $('.content-list').hide();
  $('.content-list-loading').removeClass('d-none');
}

let submitFiltersTimeout;
$(document).on('change keyup', '.auto-submit-on-change input, .auto-submit-on-change select', function() {
  // Clear the timeout to prevent the pending submission, if any
  window.clearTimeout(submitFiltersTimeout);

  // Validate datetime-local inputs
  if ($(this).attr('type') === 'datetime-local') {
    // Parse the value
    const datetime = new Date($(this).val());
    if (isNaN(datetime.getTime())) {
      window.console.error("Invalid date or time format");
      return;
    }
  }
  highlightSelectedFilters();

  // Set a timeout to submit the filters
  submitFiltersTimeout = window.setTimeout(submitFilters, 2000);
});

// NOTE: no need to implement a keypress ENTER event, pressing enter on a form input will submit the form by default
// Implement a click event on the search icon below
const autoSubmitOnClickSelector = '#content-selector-filters-form .input-group-text';
$(document).on('click', autoSubmitOnClickSelector, function() {
  // Do nothing if there is no search icon inside
  if ($(this).children('.fa-search').length === 0) {
    return;
  }
  // Clear the timeout to prevent the pending submission, if any
  window.clearTimeout(submitFiltersTimeout);

  submitFilters();
});

$(document).ready(function(){
  highlightSelectedFilters();
  $(autoSubmitOnClickSelector).each(function() {$(this).css('cursor', 'pointer');});
});
