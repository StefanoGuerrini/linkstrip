import XCTest
@testable import LinkStrip

final class URLCleanerTests: XCTestCase {
    private var cleaner: URLCleaner!

    override func setUp() {
        super.setUp()
        cleaner = URLCleaner(parameters: [
            "utm_source", "utm_medium", "utm_campaign",
            "fbclid", "gclid", "ttclid",
            "feature", "ref_src", "ref_url",
            "trk", "itm_source", "itm_medium"
        ])
    }

    func testCleanRemovesSingleTrackingParameter() {
        let input = "https://example.com/page?utm_source=newsletter"
        XCTAssertEqual(
            cleaner.clean(input),
            "https://example.com/page"
        )
    }

    func testCleanRemovesMultipleTrackingParameters() {
        let input = "https://example.com/page?utm_source=newsletter&utm_medium=email&fbclid=123"
        XCTAssertEqual(
            cleaner.clean(input),
            "https://example.com/page"
        )
    }

    func testCleanPreservesNonTrackingParameters() {
        let input = "https://example.com/search?q=swift&lang=en&utm_source=google"
        XCTAssertEqual(
            cleaner.clean(input),
            "https://example.com/search?q=swift&lang=en"
        )
    }

    func testCleanReturnsOriginalWhenNoTrackingParametersPresent() {
        let input = "https://example.com/search?q=swift&lang=en"
        XCTAssertEqual(cleaner.clean(input), input)
    }

    func testCleanHandlesURLWithOnlyTrackingParameters() {
        let input = "https://example.com/?utm_source=a&fbclid=b"
        XCTAssertEqual(
            cleaner.clean(input),
            "https://example.com/"
        )
    }

    func testCleanReturnsNilForInvalidURL() {
        XCTAssertNil(cleaner.clean("not a url"))
    }

    func testCleanHandlesFragmentAndPathCorrectly() {
        let input = "https://example.com/page#section?utm_source=bad"
        // The fragment comes after the query in URLComponents, so the query
        // is empty here; the URL is returned unchanged.
        XCTAssertEqual(cleaner.clean(input), input)
    }

    func testCleanIsCaseSensitiveForParameterNames() {
        let input = "https://example.com/page?UTM_SOURCE=newsletter"
        XCTAssertEqual(cleaner.clean(input), input)
    }

    func testCleanRedirectExtractsDestinationFromPath() {
        let input = "https://link.fndrsp.net/CL0/https://example.com/page?utm_source=newsletter"
        XCTAssertEqual(
            cleaner.cleanRedirect(input),
            "https://example.com/page"
        )
    }

    func testCleanRedirectExtractsEncodedDestinationFromPath() {
        let input = "https://link.fndrsp.net/CL0/https:%2F%2Fexample.com%2Fpage%3Futm_source%3Dnewsletter%26emailLog%3Dabc/1/0100019fdc55b137/O_ycuXgrQ5eekmWOYczw"
        XCTAssertEqual(
            cleaner.cleanRedirect(input),
            "https://example.com/page"
        )
    }

    func testCleanRedirectExtractsDestinationFromQuery() {
        let input = "https://tracker.example.com/click?url=https%3A%2F%2Fexample.com%2Fpage%3Futm_source%3Dnewsletter"
        XCTAssertEqual(
            cleaner.cleanRedirect(input),
            "https://example.com/page"
        )
    }

    func testCleanRedirectReturnsNilWhenNoRedirectPresent() {
        let input = "https://example.com/page?utm_source=newsletter"
        XCTAssertNil(cleaner.cleanRedirect(input))
    }

    func testCleanRedirectUnwrapsEvenWithoutTrackingParameters() {
        let input = "https://link.fndrsp.net/CL0/https://example.com/page"
        XCTAssertEqual(
            cleaner.cleanRedirect(input),
            "https://example.com/page"
        )
    }
}
