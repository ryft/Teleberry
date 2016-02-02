function extract_id(url) {
    if (url.length == 11) {
        return url;
    }

    // Snaffled from http://stackoverflow.com/a/8260383
    var re = /.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/;
    var id = url.match(re);
    return (id && id[1].length == 11) ? id[1] : false;
}

function build_notification(result) {
    if (result.error) {
        return '<i class="fa fa-exclamation-triangle fa-fw"></i>' + result.error;
    } else {
        return '<i class="fa fa-check fa-fw"></i>' + result.message;
    }
}

function send_command(fn, cmd) {
    $.ajax({
        method: 'POST',
        url: '/' + fn + '/' + cmd
    });
}

$(document).ready(function() {
    $('#form-queue').submit(function(event) {
        var id = extract_id($('#queue-url').val());
        if (id) {
            $.ajax({
                method: 'POST',
                url: '/queue/' + id + '/change',
                dataType: 'json'
            }).done(function(result) {
               $('#notification').html(build_notification(result));
            });
        } else {
            $('#notification').html(build_notification({
                error: "Couldn't extract YouTube video ID from URL"
            }));
        }

        event.preventDefault();
    });

    $('#control-container .btn').click(function(event) {
        var button = $(event.target);
        send_command(button.data('fn'), button.data('cmd'));
    });
});

