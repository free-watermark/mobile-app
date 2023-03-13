
icons:
	@flutter pub run flutter_launcher_icons

create.android.emulator:
	@flutter emulators --create --name android_emulator

create.ios.simulator:
	@xcrun simctl create\
		ios_simulator com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro\
		com.apple.CoreSimulator.SimRuntime.iOS-16-1 > ios_simulator_id

run.ios.simulator:
	@xcrun simctl boot $(shell cat ios_simulator_id)
	@open -a simulator

run.android.emulator:
	@flutter emulators --launch android_emulator

screenshots:
	@flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshots_test.dart
