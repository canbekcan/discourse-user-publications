import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "setup-user-publications",
  initialize() {
    // Fix #4 — Register the profile tab through the plugin API instead of a
    // user-main-nav connector. The connector approach injects a raw <li> into
    // the DOM and is skipped by the mobile dropdown renderer, which builds its
    // tab list from the same plugin-API registry that addProfileTab writes to.
    withPluginApi("1.30.0", (api) => {
      api.addProfileTab({
        name: "publications",
        route: "user.publications",
        icon: "book",
        i18nKey: "user_publications.tab_title",
      });
    });
  },
};
