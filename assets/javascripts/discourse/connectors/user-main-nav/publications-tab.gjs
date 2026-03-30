import { LinkTo } from "@ember/routing";
import i18n from "discourse-common/helpers/i18n";

<template>
  <li class="user-nav__publications">
    <LinkTo @route="user.publications">
      <svg class="fa d-icon d-icon-book svg-icon svg-string" aria-hidden="true" xmlns="http://www.w3.org/2000/svg">
        <use href="#book"></use>
      </svg>
      <span>{{i18n "user_publications.tab_title"}}</span>
    </LinkTo>
  </li>
</template>
