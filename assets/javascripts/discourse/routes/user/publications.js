import DiscourseRoute from "discourse/routes/discourse";

export default class UserPublicationsRoute extends DiscourseRoute {
  model() {
    return this.modelFor("user");
  }
}
