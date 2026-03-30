import { LinkTo } from "@ember/routing";
import i18n from "discourse-i18n";

<template>
  <li class="nav-item">
    <LinkTo @route="user.publications" @model={{@outletArgs.model.username}}>
      {{i18n "user_publications.tab_title"}}
    </LinkTo>
  </li>
</template>
