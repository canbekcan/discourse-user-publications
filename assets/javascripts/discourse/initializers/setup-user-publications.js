import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "setup-user-publications",
  initialize() {
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