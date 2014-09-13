module ResponsesHelper

  def response_form(response, attribute, required = false)
    (nested_form_for [@course, @assignment, response.question, response], remote: true do |f|
      (f.text_area attribute, class: 'submissionTextArea fl', value: response[attribute],
                   required: required,
                   rows: (response[attribute] || '').split(/\n/).length)  +
          ('<br><br>' +
              '<div class=\'savedStatus\'></div>').html_safe
    end ).html_safe

  end

  def complete_peer_review(response, user)
    response_form(response, :peer_review, response.question.written_response_required )
  end

  def see_peer_review(response, index, user)
    ("<span class='submissionResponseFrom'>" +
        (if @user.id == response.evaluation.user.id and @user == current_user
           "Your Review:&nbsp"
         else
           reviewer_name(response.evaluation, index) + "'s Review:&nbsp"
         end) +
        "</span>" +
        "<span>" + ' ' + response.scale.description + "</span>" +
        "<div class='submissionPeerReview'>#{ response.peer_review.blank? ? '' : response.peer_review.gsub(/\n/,'<br>').html_safe }</div>"
    ).html_safe
  end

  def instructor_comment(response, instructor)
    question = response.question
    submission = response.evaluation.submission
    assignment = submission.assignment
    course = assignment.course
    if instructor and Time.zone.now > assignment.submission_due and !submission.instructor_approved
      ("<div class=submissionInstructorResponse' style='margin-top:25px; margin-bottom:-3px;'>" +
          "<div class='submissionResponseFrom'>Instructors' Comments</div>" +
          response_form(response, :instructor_response) +
          "</div>").html_safe
    elsif response.instructor_response
      ("<div class='submissionResponseFrom'>Instructors' Comments</div>" +
          response.instructor_response.gsub(/\n/,'<br>')).html_safe
    else
      ''
    end
  end

  def student_rebuttal(response, user)
    question = response.question
    submission = response.evaluation.submission
    assignment = submission.assignment
    course = assignment.course
    (if @submitter and !@submission.instructor_approved   # the review is still open
       "<div class='submissionInstructorResponse'>" +
           "<div class='submissionResponseFrom' style='margin-top: 20px;'>Your Rebuttal</div>" +
           response_form(response, :student_response)  +
           "</div>"
     elsif response.student_response  # A rebuttal was made
       "<div class='submissionStudentResponse'>" +
           "<div class='submissionResponseFrom' style='margin-top: 30px;'>" +
           (@user.instructor?(course) ? submission.user.name + "'s Rebuttal":
               @submitter ? "Your Rebuttal" :
                   "Author's Rebuttal" ) +
           "</div>"  +
           "<p>#{response.student_response.gsub(/\n/,'<br>').html_safe} </p>" +
           "</div>"
     else
       ""
     end).html_safe
  end

end

