import { application } from "./application";

import AdditionalLogsController from "./additional_logs_controller";
application.register("additional-logs", AdditionalLogsController);

import CollapseToggleController from "./collapse_toggle_controller";
application.register("collapse-toggle", CollapseToggleController);

import CommunityEditController from "./community_edit_controller";
application.register("community-edit", CommunityEditController);

import NotificationsController from "./notifications_controller";
application.register("notifications", NotificationsController);

import RoleSelectorController from "./role_selector_controller";
application.register("role-selector", RoleSelectorController);

import ServerEditController from "./server_edit_controller";
application.register("server-edit", ServerEditController);

import ServerModsController from "./server_mods_controller";
application.register("server-mods", ServerModsController);

import ServerNewController from "./server_new_controller";
application.register("server-new", ServerNewController);

import ServerRewardsController from "./server_rewards_controller";
application.register("server-rewards", ServerRewardsController);
