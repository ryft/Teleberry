function extract_id(url) {
    if (url.length == 11) {
        return url;
    }

    // Snaffled from http://stackoverflow.com/a/8260383
    var re = /.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/;
    var id = url.match(re);
    return (id && id[1].length == 11) ? id[1] : false;
}

function update_notification(response) {
    $('#notification').html(
        '<i class="fa fa-fw ' + response.icon_class + '"></i> ' + response.message
    );
}

function send_command(action) {
    $.ajax({
        method: 'POST',
        url: '/' + action,
        dataType: 'json'
    }).done(function(response) {
        update_notification(response);
        if ("next_action" in response) {
            send_command(response.next_action);
        }
    });
}

$(document).ready(function() {
    $('#form-queue').submit(function(event) {
        var id = extract_id($('#queue-url').val());
        if (id) {
            send_command('queue/' + id + '/change');
        } else {
            update_notification({
                type:       'failure',
                message:    "Couldn't extract YouTube video ID from URL",
                icon_class: 'fa-exclamation-triangle'
            });
        }
        event.preventDefault();
    });

    $('#control-container .btn').click(function(event) {
        var button = $(event.target);
        send_command(button.data('fn') + '/' + button.data('cmd'));
        event.preventDefault();
    });
});

