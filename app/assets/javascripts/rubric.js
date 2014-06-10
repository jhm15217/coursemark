$(document).on('nested:fieldAdded nested:fieldRemoved ready', function(event) {
  var fields = $('.field:visible .num input');
  $.each(fields, function(index, value) {
  	$(value).val(index);
  	var percent = parseInt((100 / (fields.length-1)) * index);
  	$(value).parent().parent().children('.percentWrapper').children('.percent').html(percent + '%');
  });
})

$('.field:visible .num input').attr('disabled', 'disabled');

$('form').submit(function(event) {
  $('.field:visible .num input').removeAttr('disabled');
});
