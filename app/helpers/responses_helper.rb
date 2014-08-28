module ResponsesHelper

  def instructor_comment(response, instructor)
    question = response.question
    submission = response.evaluation.submission
    assignment = submission.assignment
    course = assignment.course
    (if instructor and Time.zone.now > assignment.submission_due and !submission.instructor_approved
       "<div class=submissionInstructorResponse' style='margin-top:25px; margin-bottom:-3px;'>" +
           "<div class='submissionResponseFrom'>Your Comment</div>" +
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

end

