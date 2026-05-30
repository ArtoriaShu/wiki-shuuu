import React from 'react';
import { Tabs } from 'animal-island-ui';
import 'animal-island-ui/style';

const cmdContent = (
  <div>
    <p style={{ marginBottom: '0.4rem', fontSize: '0.85rem', color: '#888' }}>CMD（需管理员权限）：</p>
    <code style={{ display: 'block', marginBottom: '1rem', fontSize: '0.82rem', wordBreak: 'break-all' }}>
      curl -o install.bat https://raw.githubusercontent.com/ArtoriaShu/wiki-shuuu/master/public/install.bat && install.bat
    </code>
    <p style={{ marginBottom: '0.4rem', fontSize: '0.85rem', color: '#888' }}>PowerShell（需管理员权限）：</p>
    <code style={{ display: 'block', fontSize: '0.82rem', wordBreak: 'break-all' }}>
      {`powershell -c "irm https://raw.githubusercontent.com/ArtoriaShu/wiki-shuuu/master/public/install.bat | iex"`}
    </code>
  </div>
);

const items = [
  { key: 'cmd', label: 'CMD', children: cmdContent },
];

export default function ScriptTabs() {
  return (
    <>
      <style>{`
        .script-tabs-wrap [class*="animal-tabs-"] {
          background: #F6F7F9 !important;
          border-color: #D8DBE3 !important;
        }
        .script-tabs-wrap [class*="animal-tabList-"] {
          background: #ECEEF2 !important;
          border-bottom-color: #D8DBE3 !important;
        }
        .script-tabs-wrap [class*="animal-tabItem-"] {
          color: #444444 !important;
        }
        .script-tabs-wrap [class*="animal-tabItem-"]:hover {
          background: color-mix(in srgb, var(--sl-color-accent), transparent 88%) !important;
          color: #444444 !important;
        }
        .script-tabs-wrap [class*="animal-active-"]:not([class*="shadow"]) {
          background: var(--sl-color-accent) !important;
          color: #fff !important;
        }
      `}</style>
      <div className="script-tabs-wrap">
        <Tabs items={items} defaultActiveKey="cmd" shadow />
      </div>
    </>
  );
}
