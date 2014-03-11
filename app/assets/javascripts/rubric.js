$(document).on('nested:fieldAdded nested:fieldRemoved', function(event) {
  var fields = $('.field:visible .num input');
  $.each(fields, function(index, value) {
  	$(value).val(index+1);
  });
})

$('.field:visible .num input').attr('disabled', 'disabled');

$('form').submit(function(event) {
  $('.field:visible .num input').removeAttr('disabled');
});