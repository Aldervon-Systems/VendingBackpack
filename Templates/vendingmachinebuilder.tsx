import React, { useState } from 'react';
import {
  Plus,
  Trash2,
  Save,
  Settings,
  PackageOpen,
  GripVertical,
  X,
  AlertCircle
} from 'lucide-react';

// --- Initial Data ---
const generateId = () => crypto.randomUUID();

const defaultInitialGrid = Array(4).fill(null).map(() =>
  Array(5).fill(null).map(() => ({ id: generateId(), sku: null, name: null }))
);

// --- Main Application Component ---
export default function App({ initialConfig, onSave }) {
  const [grid, setGrid] = useState(initialConfig || defaultInitialGrid);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [activePosition, setActivePosition] = useState(null);
  const [formData, setFormData] = useState({ sku: '', name: '' });
  const [formError, setFormError] = useState('');

  // Drag & Drop State
  const [dragSource, setDragSource] = useState(null);
  const [dragOverPos, setDragOverPos] = useState(null);

  // --- Grid Manipulation ---
  const addRow = () => {
    setGrid([...grid, [{ id: generateId(), sku: null, name: null }]]);
  };

  const removeRow = (rIdx) => {
    const newGrid = grid.filter((_, idx) => idx !== rIdx);
    setGrid(newGrid);
  };

  const addSlot = (rIdx) => {
    const newGrid = [...grid];
    newGrid[rIdx] = [...newGrid[rIdx], { id: generateId(), sku: null, name: null }];
    setGrid(newGrid);
  };

  const removeSlot = (rIdx, cIdx) => {
    const newGrid = [...grid];
    newGrid[rIdx] = newGrid[rIdx].filter((_, idx) => idx !== cIdx);
    setGrid(newGrid);
  };

  // --- Modal Handlers ---
  const openModal = (rIdx, cIdx) => {
    const slot = grid[rIdx][cIdx];
    setActivePosition({ rIdx, cIdx });
    setFormData({ sku: slot.sku || '', name: slot.name || '' });
    setFormError('');
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setActivePosition(null);
  };

  const handleSaveSlot = (e) => {
    e.preventDefault();
    if (!activePosition) return;

    if (!formData.sku.trim() || !formData.name.trim()) {
      setFormError('Both SKU and Name are required.');
      return;
    }

    const { rIdx, cIdx } = activePosition;
    const newGrid = [...grid];
    newGrid[rIdx][cIdx] = {
      ...newGrid[rIdx][cIdx],
      sku: formData.sku.trim(),
      name: formData.name.trim()
    };

    setGrid(newGrid);
    closeModal();
  };

  const handleClearSlot = () => {
    if (!activePosition) return;
    const { rIdx, cIdx } = activePosition;
    const newGrid = [...grid];
    newGrid[rIdx][cIdx] = { ...newGrid[rIdx][cIdx], sku: null, name: null };
    setGrid(newGrid);
    closeModal();
  };

  // --- Drag & Drop Handlers ---
  const handleDragStart = (e, rIdx, cIdx) => {
    setDragSource({ rIdx, cIdx });
    e.dataTransfer.effectAllowed = 'move';
  };

  const handleDragOver = (e, rIdx, cIdx) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';

    if (dragOverPos?.rIdx !== rIdx || dragOverPos?.cIdx !== cIdx) {
      setDragOverPos({ rIdx, cIdx });
    }
  };

  const handleDragLeave = () => {
    setDragOverPos(null);
  };

  const handleDrop = (e, targetRIdx, targetCIdx) => {
    e.preventDefault();
    setDragOverPos(null);

    if (!dragSource) return;
    const { rIdx: srcRIdx, cIdx: srcCIdx } = dragSource;

    // Prevent dropping on itself
    if (srcRIdx === targetRIdx && srcCIdx === targetCIdx) {
      setDragSource(null);
      return;
    }

    // Swap the slot data
    const newGrid = [...grid];
    const srcData = { ...newGrid[srcRIdx][srcCIdx] };
    const targetData = { ...newGrid[targetRIdx][targetCIdx] };

    newGrid[srcRIdx][srcCIdx] = {
      ...newGrid[srcRIdx][srcCIdx],
      sku: targetData.sku,
      name: targetData.name
    };

    newGrid[targetRIdx][targetCIdx] = {
      ...newGrid[targetRIdx][targetCIdx],
      sku: srcData.sku,
      name: srcData.name
    };

    setGrid(newGrid);
    setDragSource(null);
  };

  const handleDragEnd = () => {
    setDragSource(null);
    setDragOverPos(null);
  };

  // --- Export / Integration ---
  const handleExport = () => {
    if (onSave) {
      // Integration mode: Send data back to parent
      onSave(grid);
    } else {
      // Standalone mode: Download as JSON file
      const config = JSON.stringify(grid, null, 2);
      const blob = new Blob([config], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'vending-machine-config.json';
      a.click();
      URL.revokeObjectURL(url);
    }
  };

  return (
    <div className="min-h-screen bg-slate-300 text-slate-800 font-sans p-4 md:p-8 flex items-center justify-center">

      {/* Main Solid Panel - Vending Machine Shell */}
      <div className="w-full max-w-6xl mx-auto bg-slate-800 rounded-[2rem] shadow-2xl border-8 border-slate-900 overflow-hidden flex flex-col relative">

        {/* Header - Marquee */}
        <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 p-6 md:px-10 md:py-8 border-b-8 border-slate-950 bg-slate-900">
          <div>
            <h1 className="text-2xl font-black text-white flex items-center gap-3 tracking-wide">
              <PackageOpen className="text-blue-500" size={32} />
              VENDING MODIFIER
            </h1>
            <p className="text-slate-400 text-sm mt-1 font-medium">
              Configure rows, slots, and assign SKUs. Drag and drop to rearrange.
            </p>
          </div>
          <button
            onClick={handleExport}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold transition-colors shadow-[0_0_15px_rgba(37,99,235,0.5)] border border-blue-400"
          >
            <Save size={20} />
            {onSave ? 'Save Configuration' : 'Export JSON'}
          </button>
        </header>

        {/* Main Grid Area - Behind the "Glass" */}
        <div className="relative mx-4 md:mx-8 my-8 bg-slate-100 rounded-xl border-[12px] border-slate-700 shadow-[inset_0_10px_30px_rgba(0,0,0,0.5)] p-4 md:p-6 overflow-hidden">

          {/* Subtle glass reflection effect */}
          <div className="absolute top-0 left-0 w-full h-1/2 bg-gradient-to-b from-white/20 to-transparent pointer-events-none z-0"></div>

          <main className="space-y-8 relative z-10">
            {grid.map((row, rIdx) => (
              <div key={rIdx} className="overflow-x-auto pb-4 border-b-[16px] border-slate-800 rounded-b-sm">

                {/* Row Header - Shelf Label */}
                <div className="flex justify-between items-center mb-4 min-w-max pr-2 bg-slate-200/50 p-2 rounded-t-lg">
                  <div className="flex items-center gap-3">
                    <div className="bg-slate-900 text-blue-400 border-2 border-slate-700 shadow-inner text-xs font-black px-4 py-1.5 rounded-sm uppercase tracking-widest">
                      Row {rIdx + 1}
                    </div>
                    <span className="text-sm text-slate-500 font-bold bg-white px-2 py-1 rounded shadow-sm border border-slate-200">
                      {row.length} Slots
                    </span>
                  </div>
                  <button
                    onClick={() => removeRow(rIdx)}
                    className="text-slate-400 hover:text-red-500 hover:bg-red-50 rounded p-1.5 transition-colors"
                    title="Remove Row"
                  >
                    <Trash2 size={20} />
                  </button>
                </div>

                {/* Slots Container */}
                <div className="flex gap-4 min-w-max pb-2 px-2">
                  {row.map((slot, cIdx) => {
                    const isDragSource = dragSource?.rIdx === rIdx && dragSource?.cIdx === cIdx;
                    const isDragOver = dragOverPos?.rIdx === rIdx && dragOverPos?.cIdx === cIdx;
                    const hasItem = !!slot.sku;

                    return (
                      <div
                        key={slot.id}
                        className="relative group flex flex-col items-center"
                      >
                        {/* Slot Box */}
                        <div
                          draggable
                          onDragStart={(e) => handleDragStart(e, rIdx, cIdx)}
                          onDragOver={(e) => handleDragOver(e, rIdx, cIdx)}
                          onDragLeave={handleDragLeave}
                          onDrop={(e) => handleDrop(e, rIdx, cIdx)}
                          onDragEnd={handleDragEnd}
                          onClick={() => openModal(rIdx, cIdx)}
                          className={`
                            w-28 h-36 rounded-lg border-2 cursor-pointer flex flex-col items-center justify-center p-2 text-center transition-all bg-white shadow-md
                            ${isDragSource ? 'opacity-40 scale-95' : 'opacity-100 hover:-translate-y-1 hover:shadow-lg'}
                            ${isDragOver ? 'border-blue-500 bg-blue-50 ring-4 ring-blue-500/20' : ''}
                            ${!isDragOver && hasItem ? 'border-blue-300' : ''}
                            ${!isDragOver && !hasItem ? 'border-dashed border-slate-300 bg-slate-50' : ''}
                          `}
                        >
                          {hasItem ? (
                            <>
                              <div className="absolute top-2 left-2 text-slate-300 opacity-0 group-hover:opacity-100 transition-opacity cursor-grab active:cursor-grabbing">
                                <GripVertical size={16} />
                              </div>
                              <PackageOpen className="text-blue-500 mb-2 drop-shadow-sm" size={32} />
                              <span className="font-black text-slate-800 text-sm mb-1 truncate w-full">{slot.sku}</span>
                              <span className="text-xs text-slate-500 font-medium truncate w-full px-1">{slot.name}</span>
                            </>
                          ) : (
                            <span className="text-slate-400 text-sm font-bold flex flex-col items-center gap-2">
                              <Plus size={20} /> Add SKU
                            </span>
                          )}
                        </div>

                        {/* Delete Slot Button */}
                        <button
                          onClick={(e) => { e.stopPropagation(); removeSlot(rIdx, cIdx); }}
                          className="absolute -top-2 -right-2 bg-white text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-full p-1 shadow-md border border-slate-200 opacity-0 group-hover:opacity-100 transition-opacity z-10"
                        >
                          <X size={14} />
                        </button>

                        {/* Slot Label underneath (like the selection codes on a vending machine) */}
                        <div className="bg-slate-800 text-white text-[11px] font-black font-mono mt-3 px-3 py-1 rounded shadow-inner border border-slate-900">
                          {String.fromCharCode(65 + rIdx)}{cIdx + 1}
                        </div>
                      </div>
                    );
                  })}

                  {/* Add Slot Button */}
                  <button
                    onClick={() => addSlot(rIdx)}
                    className="w-16 h-36 rounded-lg border-2 border-dashed border-slate-300 bg-slate-50/50 hover:bg-slate-100 hover:border-blue-400 flex items-center justify-center text-slate-400 hover:text-blue-500 transition-all shadow-inner"
                    title="Add Slot to Row"
                  >
                    <Plus size={28} />
                  </button>
                </div>

              </div>
            ))}

            {/* Add Row Button */}
            <button
              onClick={addRow}
              className="w-full py-6 border-4 border-dashed border-slate-300 rounded-xl text-slate-500 font-black tracking-wide hover:bg-white hover:border-blue-400 hover:text-blue-600 transition-all flex items-center justify-center gap-2 mt-4 bg-slate-50/50"
            >
              <Plus size={24} /> ADD NEW SHELF
            </button>
          </main>
        </div>

        {/* Dispenser Flap Area */}
        <div className="mx-8 md:mx-16 mb-10 h-32 bg-slate-950 rounded-xl border-[6px] border-slate-900 shadow-[inset_0_20px_20px_rgba(0,0,0,0.8)] relative overflow-hidden flex items-start justify-center group cursor-pointer">
          <div className="absolute top-0 w-full h-1/2 bg-slate-800/80 border-b-2 border-slate-900 flex items-center justify-center origin-top transition-transform duration-300 group-hover:-rotate-12 group-hover:bg-slate-700 shadow-lg">
            <span className="text-slate-900 font-black tracking-[0.3em] text-2xl drop-shadow-[0_1px_1px_rgba(255,255,255,0.2)]">PUSH</span>
          </div>
        </div>

      </div>

      {/* --- Modal Overlay --- */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">

            <div className="flex justify-between items-center px-6 py-4 border-b border-slate-100 bg-slate-50/50">
              <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                <Settings size={18} className="text-blue-600" />
                Configure Slot {activePosition ? `${String.fromCharCode(65 + activePosition.rIdx)}${activePosition.cIdx + 1}` : ''}
              </h3>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600">
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveSlot} className="p-6">
              {formError && (
                <div className="mb-4 p-3 bg-red-50 border border-red-100 rounded-lg flex items-start gap-2 text-red-600 text-sm">
                  <AlertCircle size={16} className="mt-0.5 shrink-0" />
                  <p>{formError}</p>
                </div>
              )}

              <div className="space-y-4">
                <div>
                  <label htmlFor="sku" className="block text-sm font-medium text-slate-700 mb-1">SKU Number</label>
                  <input
                    id="sku"
                    type="text"
                    autoFocus
                    value={formData.sku}
                    onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                    placeholder="e.g. SNK-102"
                    className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-shadow"
                  />
                </div>

                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-slate-700 mb-1">Product Name</label>
                  <input
                    id="name"
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="e.g. Potato Chips"
                    className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-shadow"
                  />
                </div>
              </div>

              <div className="mt-8 flex items-center justify-between">
                <button
                  type="button"
                  onClick={handleClearSlot}
                  className="text-sm font-medium text-red-600 hover:text-red-700 px-3 py-2 rounded-lg hover:bg-red-50 transition-colors"
                >
                  Clear Slot
                </button>

                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={closeModal}
                    className="px-4 py-2 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors shadow-sm"
                  >
                    Save Slot
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}