$(document).on('ready', function(event) {
  $('.reviews select').change(function(e) {
  	var submitterID = e.target.dataset.student;
  	var oldReviewerID = e.target.dataset.current;
  	var newReviewerID = $(e.target).find(":selected")[0].dataset.student;
  	console.log([submitterID, oldReviewerID, newReviewerID]);
  });
})