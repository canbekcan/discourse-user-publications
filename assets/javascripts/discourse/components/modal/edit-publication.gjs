import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import i18n from "discourse-common/helpers/i18n";

export default class EditPublicationModal extends Component {
  @tracked title = "";
  @tracked publication_type = "article";
  @tracked url = "";
  @tracked isSaving = false;

  @action
  setTitle(event) {
    this.title = event.target.value;
  }

  @action
  setUrl(event) {
    this.url = event.target.value;
  }

  @action
  async save() {
    this.isSaving = true;
    try {
      const result = await ajax("/user_publications", {
        type: "POST",
        data: {
          publication: {
            title: this.title,
            publication_type: this.publication_type,
            url: this.url,
          },
        },
      });
      this.args.model.onSave(result);
      this.args.closeModal();
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.isSaving = false;
    }
  }

  <template>
    <DModal @title={{i18n "user_publications.modal.title"}} @closeModal={{@closeModal}}>
      <:body>
        <div class="control-group">
          <label>{{i18n "user_publications.modal.publication_title"}}</label>
          <input
            type="text"
            class="full-width"
            value={{this.title}}
            {{on "input" this.setTitle}}
          />
        </div>

        <div class="control-group">
          <label>{{i18n "user_publications.modal.url"}}</label>
          <input
            type="url"
            class="full-width"
            value={{this.url}}
            {{on "input" this.setUrl}}
          />
        </div>
      </:body>
      <:footer>
        <DButton
          @action={{this.save}}
          @label="user_publications.modal.save"
          @isLoading={{this.isSaving}}
          class="btn-primary"
        />
        <DButton
          @action={{@closeModal}}
          @label="user_publications.modal.cancel"
        />
      </:footer>
    </DModal>
  </template>
}
