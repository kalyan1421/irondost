"""Assemble two hub artifacts: each an index.html with a sidebar that renders Markdown files."""
import html, json, os, shutil

REPO = "/Users/kalyan/Akvega clients/Irondost"
SP = os.path.dirname(os.path.abspath(__file__))
A = f"{REPO}/docs/artifacts-archive"
D = f"{REPO}/docs"

HUBS = {
  "hub-marketing": {
    "title": "IronDost Marketing Hub", "kicker": "Marketing · plans · seasons · prompts",
    "extra": {"gallery.html": os.path.expanduser("~/Downloads/Irondost-Clip-Assets/_gallery.html")},
    "nav": [
      ("Start here", [("start", "Plan of action", f"{SP}/hub-marketing/start.md")]),
      ("Plans", [
        ("board", "Marketing Board", f"{A}/marketing-board.md"),
        ("growth", "Growth plan Nov 2026 – Nov 2027", f"{D}/marketing/irondost-growth-plan-2026-27.md"),
        ("nov19", "19–30 November plan", f"{D}/marketing/irondost-november-19-30-plan.md"),
        ("domains", "Domains, website, SEO, Instagram", f"{D}/marketing/irondost-domains-website-seo-instagram-plan-2026-11-19.md"),
        ("blog", "Blog and search plan", f"{D}/marketing/blog-and-search-plan.md"),
        ("yt", "YouTube and Instagram setup", f"{D}/marketing/youtube-instagram-setup.md"),
        ("webdrafts", "Website redesign drafts", f"{D}/marketing/website-redesign-drafts.md"),
      ]),
      ("Seasons and prompts", [
        ("season1", "Dost Undi Ga! Season 1 (all prompts)", f"{A}/dost-undi-ga-season-1.md"),
        ("clips", "December clip plan", f"{A}/december-clip-plan.md"),
        ("decpack", "December pack", f"{D}/marketing/december-2026-pack/README.md"),
        ("hooks", "10 hooks", f"{D}/marketing/december-2026-pack/hooks.md"),
        ("nov17", "1–7 November launch week", f"{D}/marketing/irondost-november-1-7-social-plan.md"),
        ("novlb", "November LB Nagar plan", f"{D}/marketing/irondost-november-2026-lb-nagar-plan.md"),
        ("dasara", "Dasara launch plan", f"{D}/marketing/irondost-hyderabad-dasara-launch-plan.md"),
      ]),
      ("Local SEO", [
        ("gbp", "Google Business Profile pack", f"{D}/marketing/seo/gmb-profile-pack.md"),
        ("local", "Local SEO", f"{D}/marketing/seo/local-seo-2026-11-19.md"),
        ("seoaudit", "SEO audit", f"{D}/marketing/seo/seo-audit-2026-11-19.md"),
        ("guides", "Guides and AI files audit", f"{D}/marketing/seo/guides-audit-and-ai-files-2026-11-19.md"),
      ]),
      ("Brand and assets", [
        ("brand", "Brand guidelines", f"{A}/brand-guidelines.md"),
        ("assets", "Clip asset library", f"{A}/clip-assets.md"),
      ]),
    ],
  },
  "hub-app": {
    "title": "IronDost Build and Audit", "kicker": "App development · audits · release",
    "extra": {},
    "nav": [
      ("Start here", [("start", "Status and roadmap", f"{SP}/hub-app/start.md")]),
      ("Audits", [
        ("platform", "Cloud Ironing platform audit", f"{A}/cloud-ironing-platform-audit.md"),
        ("uiux", "UI/UX audit", f"{D}/ui-ux-audit/AUDIT.md"),
        ("critique", "Customer app critique", f"{D}/design/customer-app-critique.md"),
        ("lessons", "Lessons", f"{D}/ui-ux-audit/LESSONS.md"),
        ("market", "India laundry app research", f"{D}/india-laundry-app-ux-market-research.md"),
        ("research", "Design research", f"{D}/ui-ux-audit/DESIGN_RESEARCH.md"),
      ]),
      ("Design", [
        ("ds", "Design system and tokens", f"{A}/irondost-overview.md"),
        ("dsdoc", "Design system notes", f"{D}/ui-ux-audit/DESIGN_SYSTEM.md"),
        ("screens", "Customer app: 64 screens", f"{A}/customer-app.md"),
        ("drafts", "Customer app drafts", f"{A}/customer-app-drafts.md"),
        ("mobileplan", "Mobile UI/UX update plan", f"{D}/design/mobile-ui-ux-update-plan.md"),
        ("refresh", "UI refresh", f"{D}/customer-app-ui-refresh.md"),
        ("impl", "Implementation log", f"{D}/ui-ux-audit/IMPLEMENTATION.md"),
        ("brand", "Brand guidelines", f"{A}/brand-guidelines.md"),
      ]),
      ("Plans", [
        ("appplan", "Customer app plan", f"{D}/customer-app-plan.md"),
        ("laundry", "Laundry-first plan", f"{D}/laundry-first-plan.md"),
        ("backend", "Backend plan (trust core)", f"{REPO}/replica/plans/backend-plan.md"),
        ("build", "Build plan (incl. partner app)", f"{REPO}/replica/plans/build-plan.md"),
        ("decisions", "Decisions", f"{REPO}/replica/plans/decisions.md"),
        ("tasks", "TASKS.md (as of 7 Nov)", f"{REPO}/TASKS.md"),
      ]),
      ("Release and ops", [
        ("play", "Play Store release flow", f"{D}/play-store-release-flow.md"),
        ("release", "Customer app release", f"{D}/customer-app-release.md"),
        ("store", "Store submission assets", f"{D}/store-submission-assets.md"),
        ("render", "API deploy on Render", f"{D}/api-deploy-render.md"),
        ("cicd", "CI/CD", f"{D}/ci-cd.md"),
        ("runbook", "Staff delivery runbook", f"{D}/staff-delivery-runbook.md"),
      ]),
    ],
  },
}

TEMPLATE = open(os.path.join(SP, "hub_template.html")).read()

for key, hub in HUBS.items():
    out = os.path.join(SP, key)
    os.makedirs(os.path.join(out, "docs"), exist_ok=True)
    nav = []
    for group, items in hub["nav"]:
        g = []
        for slug, label, src in items:
            assert os.path.exists(src), src
            if src != os.path.join(out, "docs", slug + ".md"):
                shutil.copyfile(src, os.path.join(out, "docs", slug + ".md"))
            g.append({"id": slug, "label": label, "words": len(open(src).read().split())})
        nav.append({"group": group, "items": g})
    for name, src in hub["extra"].items():
        shutil.copyfile(src, os.path.join(out, name))
    page = (TEMPLATE.replace("__TITLE__", html.escape(hub["title"]))
            .replace("__KICKER__", html.escape(hub["kicker"]))
            .replace("__NAV__", json.dumps(nav))
            .replace("__GALLERY__", "true" if hub["extra"] else "false"))
    open(os.path.join(out, "index.html"), "w").write(page)
    print(key, sum(len(g["items"]) for g in nav), "docs")
