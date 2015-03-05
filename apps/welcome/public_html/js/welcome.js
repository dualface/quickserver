
var interval = 2;
var interval_60s_steps = Math.round(60 / interval);

var chart_opts = {
    axisX: {
        showLabel: true,
        offset: 20
    },
    axisY: {
        showLabel: true,
        offset: 30,
        scaleMinSpace: 20
    },
    showArea: true,
    height: 200,
    showPoint: false,
    lineSmooth: false,
    low: 0,
    high: 99,
    fullWidth: true
};

var last60s_cpu_data = {
    labels: [],
    series: [[]]
};

for (var i = 0; i < interval_60s_steps; ++i) {
    last60s_cpu_data.labels[i] = "|";
}

var last60s_cpu_opts = $.extend(true, {}, chart_opts);
last60s_cpu_opts.axisY.labelInterpolationFnc = function(value) {
    return value + '%';
};

// --

var dashboard = {};

function calc_ngx_cpu_load_at_index(data, timetype, index) {
    var set = data["NGINX_MASTER"].cpu[timetype];
    var load = set[index];
    if (load === undefined) {
        return false;
    }
    load = parseFloat(load);

    for (var ngx_index = 1; ngx_index < 100; ++ngx_index) {
        var key = "NGINX_WORKER_#" + ngx_index;
        var set = data[key];
        if (set === undefined) {
            break;
        }
        set = set.cpu[timetype];
        load = load + parseFloat(set[index]);
    }

    return load;
}

var update_last60s_busy = false;
function update_last60s() {
    if (update_last60s_busy) {
        console.log("REPEAT");
        return;
    }

    $.getJSON(dashboard.admin_url + "&time_span=60s", function(data) {
        // CPU
        $("#last60s_cpu_title").text("CPU Load (" + data.cpu_cores + " cores)");

        var cores = parseFloat(data.cpu_cores);
        var loads = {nginx: [], redis: [], beanstalkd: []};
        for (var index = 0; index < interval_60s_steps; ++index) {
            var load = calc_ngx_cpu_load_at_index(data, "last_60s", index);
            if (load === false) {
                break;
            }
            loads.nginx[index] = load;
            loads.redis[index] = parseFloat(data["REDIS-SERVER"].cpu.last_60s[index]);
            loads.beanstalkd[index] = parseFloat(data["BEANSTALKD"].cpu.last_60s[index]);
        }

        console.log("loads.nginx.length = " + loads.nginx.length.toString());
        var length = loads.nginx.length;
        var offset = interval_60s_steps - length;
        if (offset > 0) {
            for (var index = 0; index < offset; ++index) {
                last60s_cpu_data.series[0][index] = 0;
            }
        }
        for (var index = 0; index < length; ++index) {
            var idx = offset + index;
            var load = (loads.beanstalkd[index] + loads.redis[index] + loads.nginx[index]) / cores;
            if (load > 100) {
                console.log("load = " + load.toString());
                load = 100;
            }
            last60s_cpu_data.series[0][idx] = load;
        }
        dashboard.last60s_cpu_chart.update(last60s_cpu_data);

        // MEM
        update_last60s_busy = false;
        console.log("update last60s");
    });
}

$(document).ready(function() {
    var l = document.location;
    dashboard.admin_url = "http://" + l.host + "/admin?action=monitor.getdata"
    dashboard.last60s_cpu_chart = new Chartist.Line('#last60s_cpu', last60s_cpu_data, last60s_cpu_opts);

    update_last60s();
    window.setInterval(update_last60s, 1000 * interval);
});
