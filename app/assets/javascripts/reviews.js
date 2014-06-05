$(document).on('ready', function(event) {
  $('.reviews select').change(function(e) {
  	var submitterID = e.target.dataset.student;
  	var oldReviewerID = e.target.dataset.current;
  	var newReviewerID = $(e.target).find(":selected")[0].dataset.student;

  	$.ajax({
      type: "POST",
      url: window.location.pathname + '/edit_review',
      data: { submitterID: submitterID, oldReviewerID: oldReviewerID, newReviewerID: newReviewerID  }
    });
  });
})