$(document).on('nested:fieldAdded nested:fieldRemoved', function(event) {
  var fields = $('.field:visible .num');
  $.each(fields, function(index, value) {
  	$(value).html(index+1);
  });
})