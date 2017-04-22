using Toybox.Application as Application;
using Toybox.Attention as Attention;
using Toybox.WatchUi as Ui;

var timer;
var tickTimer;
var minutes = 0;
var minutesOfBreakLeft = 0;
var pomodoroNumber = 1;
var isPomodoroTimerStarted = false;
var isBreakTimerStarted = false;

function ping( dutyCycle, length ) {
	if ( Attention has :vibrate ) {
		Attention.vibrate( [ new Attention.VibeProfile( dutyCycle, length ) ] );
	}
}

function play( tone ) {
	if ( Attention has :playTone ) {
		Attention.playTone( tone );
	}
}

function isLongBreak() {
	return ( pomodoroNumber % Application.getApp().getProperty( "numberOfPomodorosBeforeLongBreak" ) ) == 0;
}

class GarmodoroDelegate extends Ui.BehaviorDelegate {
	const APP = Application.getApp();
	hidden var pomodoroLength = APP.getProperty( "pomodoroLength" );
	hidden var shortBreakLength = APP.getProperty( "shortBreakLength" );
	hidden var longBreakLength = APP.getProperty( "longBreakLength" );
	hidden var tickStrength = APP.getProperty( "tickStrength" );
	hidden var tickDuration = APP.getProperty( "tickDuration" );

	function initialize() {
		Ui.BehaviorDelegate.initialize();
	}

	function pomodoroCallback() {
		minutes -= 1;

		if ( minutes == 0 ) {
			play( Attention.TONE_LAP );
			ping( 100, 1500 );
			tickTimer.stop();
			timer.stop();
			isPomodoroTimerStarted = false;

			minutesOfBreakLeft = isLongBreak() ? me.longBreakLength : me.shortBreakLength;
			timer.start( method( :breakCallback ), 60 * 1000, true );
			isBreakTimerStarted = true;
		}

		Ui.requestUpdate();
	}

	function breakCallback() {
		minutesOfBreakLeft -= 1;

		if ( minutesOfBreakLeft == 0 ) {
			play( Attention.TONE_INTERVAL_ALERT );
			ping( 100, 1500 );
			timer.stop();

			isBreakTimerStarted = false;
			pomodoroNumber += 1;
			minutes = me.pomodoroLength;
		}

		Ui.requestUpdate();
	}

	function tickCallback() {
		ping( me.tickStrength, me.tickDuration );
	}

	function onBack() {
		return true;
	}

	function onNextMode() {
		return true;
	}

	function onNextPage() {
		return true;
	}

	function onSelect() {
		if ( isBreakTimerStarted || isPomodoroTimerStarted ) {
			Ui.pushView( new Rez.Menus.StopMenu(), new StopMenuDelegate(), Ui.SLIDE_UP );
			return true;
		}

		play( Attention.TONE_START );
		ping( 75, 1500 );
		minutes = me.pomodoroLength;
		timer.start( method( :pomodoroCallback ), 60 * 1000, true );
		if ( me.tickStrength > 0 && me.tickDuration > 0 ) {
			tickTimer.start( method( :tickCallback ), 1000, true );
		}
		isPomodoroTimerStarted = true;

		Ui.requestUpdate();

		return true;
	}

}
