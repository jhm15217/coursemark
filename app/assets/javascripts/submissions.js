var forms = document.getElementsByTagName("FORM");
var form_error = false;

$('form').on('ajax:success', function(event, data, status, xhr) {
  console.log("Status: ", status);
});
$('form').on('ajax:error', function(event, data, status, xhr) {
  console.log("Status: ", status, "   - please try again.");
  form_error = true;
});

function submitForms() {
  if (form_error) {
  	form_error = false;
  }
  for (var i=0; i<forms.length; i++) {
    $(forms[i]).trigger('submit.rails');
  }
  if (form_error) {
  	$('#submitFormsButton').html("Save Peer Review - Error please try again")
  }
}
