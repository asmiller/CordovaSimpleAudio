var exec = require('cordova/exec'),
    simpleAudio = {};

simpleAudio.play = function (file) {
    var success = function (res) {
        console.log('Success ' + res);
    };

    exec(success, null, "SimpleAudio", "play", ['file', file]);
};

simpleAudio.say = function (text) {
    var success = function (res) {
        console.log('Success ' + res);
    };

    exec(success, null, "SimpleAudio", "say", ['text', text]);
};

simpleAudio.setVolume = function (val) {
    var success = function (res) {
        console.log('Success ' + res);
    };

    exec(success, null, "SimpleAudio", "setVolume", ['val', val]);
};

simpleAudio.getVolume = function () {
    var success = function (res) {
        console.log('Success ' + res);
    };
    exec(success, null, "SimpleAudio", "getVolume");
};

module.exports = simpleAudio;
