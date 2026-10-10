import CoreLocation
import XCTest
import simd
@testable import DeadReconTaxi

/// Unit and synthetic fixture tests for AHRS / INS / NavFilter.
final class FusionNavTests: XCTestCase {
    /// Untrusted magnetometer must not yank heading to mag.
    func testMagSoftRejectKeepsGyroHeading() {
        let ahrs = SwiftAHRS()
        ahrs.reset(initialHeadingRad: 0)
        let imu = IMUSample(
            timestamp: Date(),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: .zero,
            rotationRate: .zero,
            headingDegrees: 90,
            headingAccuracy: 40,
            magTrusted: false
        )
        ahrs.predict(imu: imu, dt: 0.1)
        XCTAssertEqual(ahrs.headingRad, 0, accuracy: 1e-9)
    }

    /// Trusted magnetometer blends heading toward mag.
    func testMagTrustedUpdatesHeading() {
        let ahrs = SwiftAHRS()
        ahrs.reset(initialHeadingRad: 0)
        let imu = IMUSample(
            timestamp: Date(),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: .zero,
            rotationRate: .zero,
            headingDegrees: 90,
            headingAccuracy: 5,
            magTrusted: true
        )
        ahrs.predict(imu: imu, dt: 0.5)
        XCTAssertGreaterThan(ahrs.headingRad, 0.2)
    }

    /// Low motion for the configured duration produces a ZUPT event.
    func testZUPTDetectsStillness() {
        let geometry = makeEastRoute()
        let ahrs = SwiftAHRS()
        let ins = SwiftINS()
        let nav = SwiftNavFilter()
        let config = FusionConfig.default
        seed(nav: nav, ahrs: ahrs, ins: ins, geometry: geometry, config: config)

        let still = IMUSample(
            timestamp: Date(),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: SIMD3(0.01, 0, 0),
            rotationRate: SIMD3(0.01, 0, 0),
            headingDegrees: nil,
            headingAccuracy: -1,
            magTrusted: false
        )
        // Accumulate longer than zuptMinDurationSec.
        var eventCount = 0
        for _ in 0..<10 {
            ahrs.predict(imu: still, dt: 0.1)
            ins.predict(imu: still, headingRad: ahrs.headingRad, dt: 0.1)
            nav.predict(from: ins, headingRad: ahrs.headingRad, imu: still, dt: 0.1, config: config)
            if nav.lastZUPT != nil { eventCount += 1 }
        }
        XCTAssertEqual(eventCount, 1, "ZUPT must fire once when entering the hold")
        XCTAssertEqual(nav.state.speedMps, 0, accuracy: 1e-9)
    }

    /// Leaving stillness clears the latch so a later stop can ZUPT again.
    func testZUPTCanReenterAfterMotion() {
        let geometry = makeEastRoute()
        let ahrs = SwiftAHRS()
        let ins = SwiftINS()
        let nav = SwiftNavFilter()
        let config = FusionConfig.default
        seed(nav: nav, ahrs: ahrs, ins: ins, geometry: geometry, config: config)

        let still = IMUSample(
            timestamp: Date(),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: SIMD3(0.01, 0, 0),
            rotationRate: SIMD3(0.01, 0, 0),
            headingDegrees: nil,
            headingAccuracy: -1,
            magTrusted: false
        )
        let moving = IMUSample(
            timestamp: Date(),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: SIMD3(0.5, 0, 0),
            rotationRate: SIMD3(0.2, 0, 0),
            headingDegrees: nil,
            headingAccuracy: -1,
            magTrusted: false
        )
        var entered = 0
        for _ in 0..<10 {
            nav.predict(from: ins, headingRad: 0, imu: still, dt: 0.1, config: config)
            if nav.lastZUPT != nil { entered += 1 }
        }
        XCTAssertEqual(entered, 1)
        XCTAssertTrue(nav.isHoldingZUPT)
        nav.predict(from: ins, headingRad: 0, imu: moving, dt: 0.1, config: config)
        XCTAssertFalse(nav.isHoldingZUPT)
        entered = 0
        for _ in 0..<10 {
            nav.predict(from: ins, headingRad: 0, imu: still, dt: 0.1, config: config)
            if nav.lastZUPT != nil { entered += 1 }
        }
        XCTAssertEqual(entered, 1)
        XCTAssertTrue(nav.isHoldingZUPT)
    }

    /// One predict step keeps finite sigma and snapped coordinates.
    func testPredictStepFinite() {
        let geometry = makeEastRoute()
        let ahrs = SwiftAHRS()
        let ins = SwiftINS()
        let nav = SwiftNavFilter()
        let config = FusionConfig.default
        seed(nav: nav, ahrs: ahrs, ins: ins, geometry: geometry, config: config)

        let imu = IMUSample(
            timestamp: Date(),
            attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
            userAcceleration: SIMD3(0.2, 0, 0),
            rotationRate: .zero,
            headingDegrees: nil,
            headingAccuracy: -1,
            magTrusted: false
        )
        ahrs.predict(imu: imu, dt: 0.1)
        ins.predict(imu: imu, headingRad: ahrs.headingRad, dt: 0.1)
        let state = nav.predict(
            from: ins,
            headingRad: ahrs.headingRad,
            imu: imu,
            dt: 0.1,
            config: config
        )
        XCTAssertTrue(state.sigma.alongTrackMeters.isFinite)
        XCTAssertNotEqual(state.coordinate.latitude, 0, accuracy: 1)
    }

    /// Synthetic forward run increases route progress `s`.
    func testSyntheticStraightRouteMonotonicS() {
        let geometry = makeEastRoute()
        let ahrs = SwiftAHRS()
        let ins = SwiftINS()
        let nav = SwiftNavFilter()
        var config = FusionConfig.default
        config.zuptMinDurationSec = 10 // disable ZUPT for the fixture
        seed(nav: nav, ahrs: ahrs, ins: ins, geometry: geometry, config: config)

        var lastS = 0.0
        for i in 0..<40 {
            let imu = IMUSample(
                timestamp: Date().addingTimeInterval(Double(i) * 0.1),
                attitude: simd_quatd(ix: 0, iy: 0, iz: 0, r: 1),
                userAcceleration: SIMD3(0.15, 0, 0),
                rotationRate: .zero,
                headingDegrees: 90,
                headingAccuracy: 5,
                magTrusted: true
            )
            ahrs.predict(imu: imu, dt: 0.1)
            ins.predict(imu: imu, headingRad: ahrs.headingRad, dt: 0.1)
            let state = nav.predict(
                from: ins,
                headingRad: ahrs.headingRad,
                imu: imu,
                dt: 0.1,
                config: config
            )
            XCTAssertGreaterThanOrEqual(state.sMeters, lastS - 1e-6)
            lastS = state.sMeters
            if let snap = nav.lastSnap {
                XCTAssertLessThan(snap.residualMeters, config.corridorHalfWidthMeters)
            }
        }
        XCTAssertGreaterThan(lastS, 1)
    }

    /// Builds a short eastbound geometry.
    private func makeEastRoute() -> RouteGeometry {
        let a = CLLocationCoordinate2D(latitude: 50.45, longitude: 30.52)
        let b = CLLocationCoordinate2D(latitude: 50.45, longitude: 30.525)
        return RouteGeometry.make(coordinates: [a, b])!
    }

    /// Resets layers at route origin.
    private func seed(
        nav: SwiftNavFilter,
        ahrs: SwiftAHRS,
        ins: SwiftINS,
        geometry: RouteGeometry,
        config: FusionConfig
    ) {
        let heading = geometry.initialSegmentHeadingRad()
        ahrs.reset(initialHeadingRad: heading)
        ins.reset(originENU: .zero, headingRad: heading)
        let initial = NavState(
            eastMeters: 0,
            northMeters: 0,
            speedMps: 0,
            headingRad: heading,
            sMeters: 0,
            sigma: NavSigma(
                alongTrackMeters: config.initialAlongTrackSigmaMeters,
                crossTrackMeters: config.initialCrossTrackSigmaMeters,
                speedMps: config.initialSpeedSigmaMps,
                headingRad: config.initialHeadingSigmaRad
            ),
            timestamp: Date(),
            coordinate: geometry.origin
        )
        nav.reset(route: geometry, initial: initial)
    }
}
