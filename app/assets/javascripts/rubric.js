$(document).on('nested:fieldAdded nested:fieldRemoved ready', function(event) {
  var fields = $('.field:visible .num input');
  $.each(fields, function(index, value) {
  	$(value).val(index);
  	//console.log([index, fields.length]);
  	var percent = parseInt((100 / (fields.length-1)) * index);
  	$(value).parent().parent().parent().children('.explanation').children('.percent').html(percent);
  });
})

$('.field:visible .num input').attr('disabled', 'disabled');

$('form').submit(function(event) {
  $('.field:visible .num input').removeAttr('disabled');
});