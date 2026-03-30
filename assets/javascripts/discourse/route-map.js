// Extends the existing Discourse `user` route resource.
// Do NOT specify `path` here — that would re-declare /u/:username and
// conflict with Discourse core's route definition, breaking the router on boot.
export default {
  resource: "user",
  map() {
    this.route("publications");
  },
};
