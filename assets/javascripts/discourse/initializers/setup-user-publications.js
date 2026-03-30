import { withPluginApi } from "discourse/lib/plugin-api";
import UserPublicationsList from "../components/user-publications-list";

export default {
  name: "setup-user-publications",
  initialize() {
    withPluginApi("2.0.0", (api) => {
      api.addUserPage("publications", UserPublicationsList, {
        path: "publications",
        tabIcon: "book",
      });
    });
  },
};
