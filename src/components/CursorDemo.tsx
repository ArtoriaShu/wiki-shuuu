import React, { useEffect } from 'react';
import 'animal-island-ui/style';

export default function CursorDemo() {
  useEffect(() => {
    const style = document.createElement('style');
    style.id = 'animal-cursor-override';
    style.textContent = `
      body, body * {
        cursor: url('/cursor-icon.png') 4 0, default !important;
      }
      body a[href], body button, body [role=button], body select, body summary,
      body input[type=button], body input[type=submit], body input[type=reset],
      body input[type=checkbox], body input[type=radio] {
        cursor: url('/cursor-icon.png') 4 0, pointer !important;
      }
      body input[type=text], body input[type=search], body input[type=email],
      body input[type=password], body input[type=number], body textarea {
        cursor: url('/cursor-icon.png') 4 0, text !important;
      }
    `;
    document.head.appendChild(style);
    return () => {
      document.getElementById('animal-cursor-override')?.remove();
    };
  }, []);

  return null;
}
