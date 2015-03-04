
var interval = 5;

var chart_opts = {
    axisX: {
        showLabel: false,
        offset: 0
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
    series: [
        [], // beanstalkd
        [], // redis
        []  // nginx
    ]
};

for (var i = 0; i < 60 / interval; ++i) {
    last60s_cpu_data.labels[i] = "";
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
        for (var index = 0; index < 60 / interval; ++index) {
            var load = calc_ngx_cpu_load_at_index(data, "last_60s", index);
            if (load === false) {
                break;
            }
            loads.nginx[index] = load;
            loads.redis[index] = parseFloat(data["REDIS-SERVER"].cpu.last_60s[index]);
            loads.beanstalkd[index] = parseFloat(data["BEANSTALKD"].cpu.last_60s[index]);
        }

        console.log("loads.nginx.length = " + loads.nginx.length.toString());
        for (var index = 0; index < loads.nginx.length; ++index) {
            var load1 = loads.beanstalkd[index] / cores;
            last60s_cpu_data.series[0][index] = load1;
            var load2 = loads.redis[index] / cores + load1;
            last60s_cpu_data.series[1][index] = load2;

            var load3 = loads.nginx[index] / cores + load2;
            if (load3 > 100) {
                console.log("load3 = " + load3.toString());
                load3 = 100;
            }
            last60s_cpu_data.series[2][index] = load3;
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
