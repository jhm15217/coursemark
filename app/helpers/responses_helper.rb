module ResponsesHelper

  def complete_peer_review(response, user)
    question = response.question
    nested_form_for [@course, @assignment, question, response], :remote => true  do |f|
      (("<div class='peerReviewJustification'>" +
          "<div class='submissionResponseFrom'>Comment #{question.written_response_required ? '(required)' : ''}</div>" +
          (f.text_area :peer_review, :html => {class: "reviewTextArea fl"}, :required => question.written_response_required) +
       "</div>") +
       "<div class='radio_btns'>" +
            (question.scales.sort_by {|s| s.value}.map do |scale|
              "<div class='radio_btn'>"  +
                  (f.radio_button :scale_id, scale.id) +
                  (f.label ":scale_id_#{scale.id}", "#{scale.value}% - #{scale.description}") +
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
        "<div class='submissionPeerReview'>#{!response.peer_review.blank? ? '' : response.peer_review }</div>"
    ).html_safe
  end

  def instructor_comment(response, instructor)
    question = response.question
    submission = response.evaluation.submission
    assignment = submission.assignment
    course = assignment.course
    (if instructor and Time.zone.now > assignment.submission_due and !submission.instructor_approved
       "<div class=submissionInstructorResponse' style='margin-top:25px; margin-bottom:-3px;'>" +
           "<div class='submissionResponseFrom'>Instructors' Comments</div>" +
           (nested_form_for [course, assignment, question, response], remote: true do |f|
             (f.text_area :instructor_response, class: 'submissionTextArea fl')  +
                 ('<br>' +
                     '<div class=\'savedStatus\'></div>').html_safe
           end ) +
           "</div>"
     elsif response.instructor_response
       "<div class='submissionResponseFrom'>Instructors' Comments</div>" +
           response.instructor_response
     else
       ''
     end).html_safe
  end

  def student_rebuttal(response, user)
    question = response.question
    submission = response.evaluation.submission
    assignment = submission.assignment
    course = assignment.course
    (if @submitter and !@submission.instructor_approved   # the review is still open
       "<div class='submissionInstructorResponse'>" +
           "<div class='submissionResponseFrom' style='margin-top: 20px;'>Your Rebuttal</div>" +
           (nested_form_for [course, assignment, question, response], remote: true do |f|
             (f.text_area :student_response, class:'submissionTextArea fl') +
                 ("<br>" +
                     "<div class='savedStatus'></div>").html_safe
           end) +
           "</div>"
     elsif response.student_response  # A rebuttal was made
       "<div class='submissionStudentResponse'>" +
           "<div class='submissionResponseFrom' style='margin-top: 30px;'>" +
           (@user.instructor?(course) ? submission.user.name + "'s Rebuttal":
               @submitter ? "Your Rebuttal" :
                   "Author's Rebuttal" ) +
           "</div>"  +
           "<p>#{response.student_response.html_safe.gsub(/\n/,'<br>').html_safe} </p>" +
           "</div>"
     else
       ""
     end).html_safe
  end

end

