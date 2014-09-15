var forms = document.getElementsByTagName("FORM");
var form_error = false;

$('form').on('ajax:success', function(event, data, status, xhr) {
    $($(this).parent().find('.savedStatus')[0]).html('✓ saved');
    console.log("Status: ", status);
});

$('form').on('ajax:error', function(event, data, status, xhr) {
    $($(this).parent().find('.savedStatus')[0]).html('trouble saving...retrying');
    console.log("Status: ", status, "   - please try again.");
    // Retry save
    $(this).trigger('submit.rails');

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
        $('#submitFormsButton').html("Error(s) encountered while saving. Please try again.")
    }
}

function adjust_focus(elem) {
    var newlines = elem.match(/\n/g)
    if (newlines) {elem.rows = newlines.length + 1}
    else { elem.rows = 1 }
}

(function(f){function l(g,h){function d(a){if(!e){e=true;c.start&&c.start(a,b)}}function i(a,j){if(e){clearTimeout(k);k=setTimeout(function(){e=false;c.stop&&c.stop(a,b)},j>=0?j:c.delay)}}var c=f.extend({start:null,stop:null,delay:400},h),b=f(g),e=false,k;b.keypress(d);b.keydown(function(a){if(a.keyCode===8||a.keyCode===46)d(a)});b.keyup(i);b.blur(function(a){i(a,0)})}f.fn.typing=function(g){return this.each(function(h,d){l(d,g)})}})(jQuery);

for (var i=0; i<forms.length; i++) {
    var textarea = $(forms[i]).find('textarea[class="submissionTextArea fl"]')[0];
    var textarea2 = $(forms[i]).find('textarea[name="response[peer_review]"]')[0];

    // Checkbox change
    var checkbox = $(forms[i]).find('input[name="response[scale_id]"]').parent().parent();
    checkbox.change(function(){
        console.log('changed radio button');

        var commentRequired = $(this).parent().find('.peerReviewJustification textarea').attr('required');
        var existingComment = $(this).parent().find('.peerReviewJustification textarea').val();

        if (commentRequired && !existingComment) {
            $(this).parent().find('.peerReviewJustification textarea').val(' ');
        }

        $(this).parent().parent().find('.savedStatus').html('saving...');
        $($(this).parent()[0]).trigger('submit.rails');

    });

    // Textarea change
    $(textarea).typing({
        start: function (event, $elem) {
            $($elem.parent().parent().find('.savedStatus')[0]).html('typing...');
        },
        stop: function (event, $elem) {
            var tb = $($elem);
            tb.height(tb.prop('scrollHeight'));

            $($elem.parent().parent().find('.savedStatus')[0]).html('saving...');
            $($elem.parent()[0]).trigger('submit.rails');
        },
        delay: 1000
    });
    $(textarea2).typing({
        start: function (event, $elem) {
            $($elem.parent().parent().find('.savedStatus')[0]).html('typing...');
        },
        stop: function (event, $elem) {
            var tb = $($elem);
            tb.height(tb.prop('scrollHeight'));

            $($elem.parent().parent().find('.savedStatus')[0]).html('saving...');
            $($elem.parent()[0]).trigger('submit.rails');
        },
        delay: 1000
    });
}
