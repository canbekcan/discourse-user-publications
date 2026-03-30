import { LinkTo } from "@ember/routing";
import i18n from "discourse-common/helpers/i18n";

<template>
  <li class="user-nav__publications">
    <LinkTo @route="user.publications">
      {{i18n "user_publications.tab_title"}}
    </LinkTo>
  </li>
</template>
