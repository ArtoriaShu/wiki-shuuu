import React, { useEffect, useRef } from 'react';
import { Table } from 'animal-island-ui';
import 'animal-island-ui/style';

const columns = [
  { title: '工具', dataIndex: 'tool', width: 120 },
  {
    title: '用途',
    dataIndex: 'desc',
    render: (value: unknown) => (
      <span style={{
        padding: '4px 12px',
        background: 'rgba(100, 116, 139, 0.1)',
        borderRadius: 20,
        color: '#64748b',
        fontWeight: 600,
        fontSize: 12,
      }}>
        {value as string}
      </span>
    ),
  },
];

const data = [
  { key: '1', tool: 'PixPin',     desc: '截图、贴图、OCR 文字识别' },
  { key: '2', tool: 'EcoPaste',   desc: '剪贴板历史管理，快速复用复制内容' },
  { key: '3', tool: 'Pot',        desc: '划词翻译，支持多种翻译引擎' },
  { key: '4', tool: 'Everything', desc: '全盘文件秒搜，比系统搜索快得多' },
  { key: '5', tool: 'InputTips',  desc: '输入法状态提示，显示当前中英文状态' },
];

export default function ToolTable() {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ref.current) return;
    const fix = () => {
      const inner = ref.current?.querySelector<HTMLElement>('div[style]');
      if (inner) {
        inner.style.setProperty('width', '100%', 'important');
        inner.style.setProperty('overflow', 'visible', 'important');
      }
    };
    fix();
    const observer = new MutationObserver(fix);
    observer.observe(ref.current, { childList: true, subtree: true });
    return () => observer.disconnect();
  }, []);

  return (
    <>
      <style>{`
        .tool-table-wrap .animal-wrapper-LJBly {
          background: #F6F7F9 !important;
        }
        .tool-table-wrap .animal-thead-2ge5M,
        .tool-table-wrap .animal-tbody-3RGsp {
          background: #F6F7F9 !important;
        }
        .tool-table-wrap .animal-headerRow-sAsWX::after,
        .tool-table-wrap .animal-row-iDOMw::after {
          background: repeating-linear-gradient(90deg, #D8DBE3 0, #D8DBE3 6px, transparent 6px, transparent 12px) !important;
        }
        .tool-table-wrap .animal-headerCell-LhL6h {
          color: #444444 !important;
          padding: 16px 20px !important;
        }
        .tool-table-wrap .animal-cell-4PAU2 {
          color: #444444 !important;
          padding: 14px 20px !important;
        }
        .tool-table-wrap .animal-striped-8Ih-N {
          background: #ECEEF2 !important;
        }
        .tool-table-wrap .animal-row-iDOMw:hover {
          background-image: repeating-linear-gradient(-45deg, #D8DBE399, #D8DBE399 10px, #ECEEF299 10px 20px) !important;
          background-size: 28.28px 28.28px;
        }
        .tool-table-wrap .animal-row-iDOMw:hover .animal-cell-4PAU2 {
          color: #444444 !important;
        }
      `}</style>
      <div className="tool-table-wrap" ref={ref} style={{ width: '100%' }}>
        <Table columns={columns} dataSource={data} striped />
      </div>
    </>
  );
}
