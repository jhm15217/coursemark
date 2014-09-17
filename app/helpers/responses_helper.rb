module ResponsesHelper

  def smart_textbox(name, content = '', required = nil)
    "<textarea onKeyUp='textAreaAdjust(this);' style='overflow:hidden' html='{:class=>&quot;submissionTextArea fl&quot;}' " +
    "rows='#{(content || '').split(/\n/).length + 1}'" +
    "class='submissionTextArea fl' id='response_#{name}' name='response[#{name}]' overflow='auto' >#{content}</textarea>"
  end

  def complete_peer_review(response, user)
    question = response.question
    nested_form_for [@course, @assignment, question, response], :remote => true  do |f|
      (("<div class='peerReviewJustification' >" +
          "<div class='submissionResponseFrom'>Comment #{question.written_response_required ? '(required)' : ''}</div>" +
          smart_textbox('peer_review', response.peer_review, response.question.written_response_required) +
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
        nested_form_for [@course, @assignment, response.question, response], remote: true do |f|
            ("<div class='peerReviewJustification'>" +
               "<div class='submissionResponseFrom'>Instructors' Comments</div>" +
                smart_textbox('instructor_response', response.instructor_response) +
               "</div>" +
               "<br>" +
               '<div class=\'savedStatus\'></div>' +
              "</div>").html_safe
        end
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
       ("<div class='submissiontStudentResponse'>" +
           "<div class='submissionResponseFrom' style='margin-top: 20px;'>Your Rebuttal</div>" +
           (nested_form_for [@course, @assignment, response.question, response], remote: true do |f|
             (smart_textbox('student_response',response.student_response)).html_safe +
                 '<div class=\'savedStatus\'></div>'.html_safe
           end ).html_safe  +
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

