import DIcon from "discourse/components/d-icon";
import { LinkTo } from "@ember/routing";
import i18n from "discourse-i18n";

<template>
  <li class="user-nav__publications">
    <LinkTo @route="user.publications" @model={{@outletArgs.model.username}}>
      <DIcon @icon="book" />
      <span>{{i18n "user_publications.tab_title"}}</span>
    </LinkTo>
  </li>
</template>
