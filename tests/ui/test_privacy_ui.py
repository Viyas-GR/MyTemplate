from playwright.sync_api import Page, expect


def test_privacy_link_from_landing_page(page: Page):
    """Verify users can reach the Privacy Policy from the landing page."""
    page.goto("http://127.0.0.1:5000/")

    expect(page).to_have_title("MyTemplate")

    page.get_by_role("link", name="Privacy").click()

    expect(page).to_have_url("http://127.0.0.1:5000/privacy")
    expect(page.get_by_role("heading", name="PRIVACY POLICY")).to_be_visible()
