<script setup lang="ts">
import { onLaunch, onShow, onHide } from "@dcloudio/uni-app";

onLaunch(() => {
  console.log("[App Launch] ZKBrain Uni-app BCI engine initialized");
});
onShow(() => {});
onHide(() => {});
</script>

<style>
/* 全局页面浅灰底色，贴合 shared1 原生质感 */
page {
  background-color: #f1f5f9;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  box-sizing: border-box;
}
</style>
