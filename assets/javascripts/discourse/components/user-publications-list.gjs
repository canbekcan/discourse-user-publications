import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import EditPublicationModal from "./modal/edit-publication";

export default class UserPublicationsList extends Component {
  @service modal;

  @action
  openAddModal() {
    this.modal.show(EditPublicationModal, {
      model: {
        user: this.args.user,
        onSave: (newPub) => this.args.user.publications.pushObject(newPub),
      },
    });
  }

  @action
  async syncOrcid() {
    try {
      await ajax(`/user_publications/${this.args.user.username}/sync`, {
        type: "POST",
      });
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    <div class="user-publications-container">
      <div class="publications-header">
        <h3>Publications</h3>
        <div class="actions">
          <DButton
            @action={{this.syncOrcid}}
            @icon="arrows-rotate"
            @label="user_publications.sync"
          />
          <DButton
            @action={{this.openAddModal}}
            @icon="plus"
            @label="user_publications.add_new"
            class="btn-primary"
          />
        </div>
      </div>

      <ul class="publications-list">
        {{#each @user.publications as |pub|}}
          <li>
            <strong>{{pub.title}}</strong>
            <span class="pub-type">({{pub.publication_type}})</span>
            {{#if pub.url}}
              <a href={{pub.url}} target="_blank" rel="noopener noreferrer">Link</a>
            {{/if}}
          </li>
        {{/each}}
      </ul>
    </div>
  </template>
}
