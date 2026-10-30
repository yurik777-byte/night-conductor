// Generates NightConductorPrototype.rbxlx from the source tree.
// Usage: node build-rbxlx.js
const fs = require("fs");
const path = require("path");

const root = __dirname;
let referent = 0;

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), "utf8");
}

function escapeXml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function nextRef() {
  referent += 1;
  return "RBX" + referent;
}

function item(className, name, children = [], properties = []) {
  const ref = nextRef();
  const lines = [];
  lines.push(`  <Item class="${className}" referent="${ref}">`);
  lines.push("    <Properties>");
  lines.push(`      <string name="Name">${escapeXml(name)}</string>`);
  for (const property of properties) {
    lines.push("      " + property);
  }
  lines.push("    </Properties>");

  for (const child of children) {
    lines.push(child);
  }

  lines.push("  </Item>");
  return lines.join("\n");
}

function scriptItem(className, name, source) {
  const safeSource = source.replace(/]]>/g, "]]]]><![CDATA[>");
  return item(className, name, [], [
    `<ProtectedString name="Source"><![CDATA[${safeSource}]]></ProtectedString>`,
  ]);
}

function folder(name, children = []) {
  return item("Folder", name, children);
}

function moduleScript(name, relativePath) {
  return scriptItem("ModuleScript", name, read(relativePath));
}

const baseplate = item("Part", "Baseplate", [], [
  `<bool name="Anchored">true</bool>`,
  `<Vector3 name="size"><X>260</X><Y>2</Y><Z>260</Z></Vector3>`,
  `<CoordinateFrame name="CFrame">`,
  `  <X>0</X><Y>-1</Y><Z>0</Z>`,
  `  <R00>1</R00><R01>0</R01><R02>0</R02>`,
  `  <R10>0</R10><R11>1</R11><R12>0</R12>`,
  `  <R20>0</R20><R21>0</R21><R22>1</R22>`,
  `</CoordinateFrame>`,
  `<Color3uint8 name="Color3uint8">4286611584</Color3uint8>`,
  `<token name="Material">256</token>`,
  `<token name="TopSurface">0</token>`,
  `<token name="BottomSurface">0</token>`,
]);

const shared = folder("Shared", [
  moduleScript("Config", "src/ReplicatedStorage/Shared/Config.lua"),
  moduleScript("Remotes", "src/ReplicatedStorage/Shared/Remotes.lua"),
]);

const buildInfo = item("StringValue", "BUILD_INFO", [], [
  `<string name="Value">NIGHT_CONDUCTOR_PROTOTYPE_V7</string>`,
]);

const server = folder("Server", [
  scriptItem("Script", "Bootstrap", read("src/ServerScriptService/Server/Bootstrap.server.lua")),
  moduleScript("GameService", "src/ServerScriptService/Server/GameService.lua"),
  moduleScript("PassengerFactory", "src/ServerScriptService/Server/PassengerFactory.lua"),
  moduleScript("WorldBuilder", "src/ServerScriptService/Server/WorldBuilder.lua"),
]);

const clientScript = scriptItem(
  "LocalScript",
  "ClientMain",
  read("src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua")
);

const starterPlayerScripts = item("StarterPlayerScripts", "StarterPlayerScripts", [clientScript]);

const xml = [
  `<?xml version="1.0" encoding="utf-8"?>`,
  `<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">`,
  `  <External>null</External>`,
  `  <External>nil</External>`,
  item("Workspace", "Workspace", [baseplate]),
  item("Lighting", "Lighting"),
  item("ReplicatedStorage", "ReplicatedStorage", [buildInfo, shared]),
  item("ServerScriptService", "ServerScriptService", [server]),
  item("StarterPlayer", "StarterPlayer", [starterPlayerScripts]),
  `</roblox>`,
].join("\n");

const outputPath = path.join(root, "NightConductorPrototype.rbxlx");
fs.writeFileSync(outputPath, xml, "utf8");
console.log(`Wrote ${outputPath} (${xml.length} chars, ${referent} referents)`);
