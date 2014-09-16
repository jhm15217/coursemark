module ResponsesHelper

  def response_form(response, attribute, required = false)
    (nested_form_for [@course, @assignment, response.question, response], remote: true do |f|
      (f.text_area attribute, class: 'submissionTextArea fl', value: response[attribute],
                   required: required,
                   overflow: 'auto',
                   height: 'auto') +
      '<div class=\'savedStatus\'></div>'
    end ).html_safe
  end

  def complete_peer_review(response, user)
    question = response.question
    nested_form_for [@course, @assignment, question, response], :remote => true  do |f|
      (("<div class='peerReviewJustification' >" +
          "<div class='submissionResponseFrom'>Comment #{question.written_response_required ? '(required)' : ''}</div>" +
      "<textarea onKeyUp='textAreaAdjust(this);' style='overflow:hidden' html='{:class=>&quot;submissionTextArea fl&quot;}' id='response_peer_review' name='response[peer_review]' overflow='auto' >#{response.peer_review}</textarea>" +
          # (f.text_area :peer_review, :html => {class: "submissionTextArea fl"}, value: response[:peer_review],
          #              :required => question.written_response_required,
          #              overflow: 'auto',
          #              height: 'auto') +
      "</div>") +
      "<div class='radio_btns'>" +
      (question.scales.sort_by {|s| s.value}.map do |scale|
        "<div class='radio_btn'>"  +
            (f.radio_button :scale_id, scale.id) +
            (f.label "scale_id_#{scale.id}", "#{scale.value}% - #{scale.description}") +
        "</div>"
        end).reduce(:+) +
      "</div>" +
          "<br>" +
          "<div class='savedStatus'></div>").html_safe
    end
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
      "<div class='submissionResponseFrom'>Instructors' Comments</div>" +
          response.instructor_response.gsub(/\n/,'<br>').html_safe
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
       ("<div class='submissionInstructorResponse'>" +
           "<div class='submissionResponseFrom' style='margin-top: 20px;'>Your Rebuttal</div>" +
           response_form(response, :student_response) +
           "</div>").html_safe
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

