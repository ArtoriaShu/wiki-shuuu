import React from 'react';
import { Button } from 'animal-island-ui';
import 'animal-island-ui/style';

export default function DownloadButton() {
  const handleDownload = () => {
    const a = document.createElement('a');
    a.href = '/install.bat';
    a.download = 'install.bat';
    a.click();
  };

  return (
    <>
      <style>{`
        .download-btn-wrap {
          --animal-primary-color: var(--sl-color-accent);
          --animal-primary-color-hover: var(--sl-color-accent-high);
          --animal-primary-color-active: color-mix(in srgb, var(--sl-color-accent), #000 20%);
          --animal-primary-color-bg: color-mix(in srgb, var(--sl-color-accent), transparent 85%);
          --animal-text-color: #444444;
          --animal-border-color-hover: #444444;
          --animal-bg-color: #F6F7F9;
          --animal-bg-color-secondary: #ECEEF2;
          --animal-border-color: #D8DBE3;
        }
      `}</style>
      <span className="download-btn-wrap">
        <Button onClick={handleDownload}>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{ display: 'inline', verticalAlign: 'middle', marginRight: '6px', marginTop: '-2px' }}
          >
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
            <polyline points="7 10 12 15 17 10" />
            <line x1="12" y1="15" x2="12" y2="3" />
          </svg>
          下载 install.bat
        </Button>
      </span>
    </>
  );
}
