import { useState, useCallback, useEffect, useMemo } from 'react';
import { isDebug, useNuiEvent, fetchNui } from './hooks/useNui';

interface BlipData {
  id: string;
  coords: { x: number; y: number; z: number };
  name: string;
  sprite: number;
  color: number;
  scale: number;
}

interface SpriteOption { id: number; name: string }
interface ColorOption { id: number; name: string; hex: string }

const DEFAULT_SPRITES: SpriteOption[] = [
  { id: 1, name: "Standard Circle" },
  { id: 64, name: "House" },
  { id: 108, name: "Personal Vehicle" },
  { id: 225, name: "Standard Circle" },
];

const DEFAULT_COLORS: ColorOption[] = [
  { id: 0, name: "White", hex: "#FFFFFF" },
  { id: 1, name: "Red", hex: "#F44242" },
  { id: 2, name: "Green", hex: "#42F442" },
  { id: 3, name: "Blue", hex: "#4286F4" },
];

const MOCK_SPRITES: SpriteOption[] = [
  { id: 1, name: "Standard Circle" }, { id: 2, name: "Big Circle" }, { id: 3, name: "Small Circle" },
  { id: 7, name: "Square" }, { id: 8, name: "Big Square" }, { id: 64, name: "House" },
  { id: 108, name: "Personal Vehicle" }, { id: 110, name: "Helicopter" }, { id: 111, name: "Plane" },
  { id: 119, name: "Emergency" }, { id: 120, name: "Police Station" }, { id: 121, name: "Hospital" },
  { id: 225, name: "Doctor" }, { id: 310, name: "Bush" }, { id: 351, name: "Gun Range" },
  { id: 409, name: "Biological" }, { id: 485, name: "Charity" }, { id: 562, name: "Crate" },
  { id: 603, name: "Information" }, { id: 667, name: "Accelerator" }, { id: 769, name: "Sculpture" },
];

const MOCK_COLORS: ColorOption[] = [
  { id: 0, name: "White", hex: "#FFFFFF" }, { id: 1, name: "Red", hex: "#F44242" },
  { id: 2, name: "Green", hex: "#42F442" }, { id: 3, name: "Blue", hex: "#4286F4" },
  { id: 4, name: "Yellow", hex: "#F4F442" }, { id: 5, name: "Cyan", hex: "#42F4F4" },
  { id: 6, name: "Purple", hex: "#9B42F4" }, { id: 7, name: "Pink", hex: "#F442C5" },
  { id: 8, name: "Orange", hex: "#F49542" }, { id: 9, name: "Gray", hex: "#A0A0A0" },
  { id: 10, name: "Dark Gray", hex: "#5A5A5A" }, { id: 11, name: "Light Gray", hex: "#C8C8C8" },
  { id: 36, name: "Crimson", hex: "#DC143C" }, { id: 38, name: "Gold", hex: "#FFD700" },
  { id: 42, name: "Lime", hex: "#00FF00" }, { id: 48, name: "Magenta", hex: "#FF00FF" },
  { id: 50, name: "Sea Green", hex: "#2E8B57" }, { id: 58, name: "Turquoise", hex: "#40E0D0" },
  { id: 65, name: "Peru", hex: "#CD853F" }, { id: 85, name: "Ghost White", hex: "#F8F8FF" },
];

export default function App() {
  const [visible, setVisible] = useState(isDebug);
  const [blips, setBlips] = useState<BlipData[]>([]);
  const [view, setView] = useState<'list' | 'add' | 'edit'>('list');
  const [editingBlip, setEditingBlip] = useState<BlipData | null>(null);
  const [form, setForm] = useState({ name: '', color: 0, scale: 0.8, sprite: 1 });
  const [sprites, setSprites] = useState<SpriteOption[]>(isDebug ? MOCK_SPRITES : DEFAULT_SPRITES);
  const [colors, setColors] = useState<ColorOption[]>(isDebug ? MOCK_COLORS : DEFAULT_COLORS);
  const [spriteSearch, setSpriteSearch] = useState('');
  const [showSpriteDropdown, setShowSpriteDropdown] = useState(false);

  const filteredSprites = useMemo(() => {
    if (!spriteSearch) return sprites;
    const search = spriteSearch.toLowerCase();
    return sprites.filter(s => s.name.toLowerCase().includes(search) || s.id.toString().includes(search));
  }, [sprites, spriteSearch]);

  const selectedSprite = useMemo(() => sprites.find(s => s.id === form.sprite), [sprites, form.sprite]);
  const getColorHex = (id: number) => colors.find(c => c.id === id)?.hex || '#FFFFFF';

  useNuiEvent('open', (data: { blips?: Record<string, Omit<BlipData, 'id'>>; sprites?: SpriteOption[]; colors?: ColorOption[] }) => {
    if (data.sprites) setSprites(data.sprites);
    if (data.colors) setColors(data.colors);
    if (data.blips) {
      setBlips(Object.entries(data.blips).map(([id, blip]) => ({ ...blip, id })));
    }
    setVisible(true);
  });

  useNuiEvent('close', () => setVisible(false));
  useNuiEvent('blipsUpdated', (data: { blips: Record<string, Omit<BlipData, 'id'>> }) => {
    setBlips(Object.entries(data.blips).map(([id, blip]) => ({ ...blip, id })));
  });

  const handleClose = useCallback(() => {
    setVisible(false);
    fetchNui('close', {}, { success: true });
  }, []);

  const fetchBlips = useCallback(async () => {
    const data = await fetchNui<{ blips: Record<string, Omit<BlipData, 'id'>> }>('getBlips', {}, { blips: {} });
    setBlips(Object.entries(data.blips || {}).map(([id, blip]) => ({ ...blip, id })));
  }, []);

  useEffect(() => {
    if (visible) fetchBlips();
  }, [visible, fetchBlips]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [handleClose]);

  const handleCreate = async () => {
    if (!form.name.trim()) return;
    await fetchNui('createBlip', { name: form.name, sprite: form.sprite, color: form.color, scale: form.scale }, { success: true });
    setForm({ name: '', color: 0, scale: 0.8, sprite: 1 });
    setSpriteSearch('');
    setView('list');
    fetchBlips();
  };

  const handleEdit = async () => {
    if (!editingBlip) return;
    await fetchNui('editBlip', { blipId: editingBlip.id, sprite: form.sprite, color: form.color, scale: form.scale }, { success: true });
    setEditingBlip(null);
    setForm({ blipId: '', name: '', color: 0, scale: 0.8, sprite: 1 });
    setSpriteSearch('');
    setView('list');
    fetchBlips();
  };

  const handleDelete = async (blipId: string) => {
    await fetchNui('deleteBlip', { blipId }, { success: true });
    fetchBlips();
  };

  const handleShare = async (blipId: string) => {
    await fetchNui('shareBlip', { blipId }, { success: true });
  };

  const openEdit = (blip: BlipData) => {
    setEditingBlip(blip);
    setForm({ name: blip.name, color: blip.color, scale: blip.scale, sprite: blip.sprite });
    setSpriteSearch('');
    setView('edit');
  };

  if (!visible) return null;

  return (
    <div className="fixed inset-0 flex items-center justify-center p-4 bg-transparent">
      <div className="w-[520px] max-h-[85vh] bg-[rgba(15,15,20,0.92)] border border-[rgba(227,42,241,0.3)] rounded-2xl shadow-[0_0_60px_rgba(227,42,241,0.25)] overflow-hidden">
        <header className="flex items-center justify-between px-6 py-4 border-b border-[rgba(227,42,241,0.2)]">
          <h1 className="text-white text-lg font-medium tracking-wide">Personal Blips</h1>
          <button onClick={handleClose} className="w-8 h-8 flex items-center justify-center text-white/50 hover:text-[#E32AF1] transition-colors">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </header>

        <div className="p-5 max-h-[calc(85vh-140px)] overflow-y-auto">
          {view === 'list' && (
            <>
              <button onClick={() => setView('add')} className="w-full py-3 mb-5 bg-gradient-to-r from-[#E32AF1] to-[#c41ed6] text-white font-medium rounded-lg hover:shadow-[0_0_20px_rgba(227,42,241,0.4)] transition-all">
                + Add New Blip
              </button>

              {blips.length === 0 ? (
                <div className="text-center py-12 text-white/40">No blips yet. Create your first one!</div>
              ) : (
                <div className="space-y-3">
                  {blips.map(blip => (
                    <div key={blip.id} className="group p-4 bg-white/[0.03] border border-white/[0.06] rounded-xl hover:border-[#E32AF1]/40 transition-all">
                      <div className="flex items-center gap-3 mb-3">
                        <div className="w-3 h-3 rounded-full" style={{ backgroundColor: getColorHex(blip.color) }} />
                        <span className="text-white font-medium truncate flex-1">{blip.name}</span>
                        <span className="text-white/30 text-xs">ID: {blip.id}</span>
                      </div>
                      <div className="flex gap-2">
                        <button onClick={() => handleShare(blip.id)} className="flex-1 py-2 text-xs text-[#31b6ff] bg-[#31b6ff]/10 border border-[#31b6ff]/20 rounded-lg hover:bg-[#31b6ff]/20 transition-all">Share</button>
                        <button onClick={() => openEdit(blip)} className="flex-1 py-2 text-xs text-white/70 bg-white/[0.04] border border-white/10 rounded-lg hover:bg-white/[0.08] hover:text-white transition-all">Edit</button>
                        <button onClick={() => handleDelete(blip.id)} className="flex-1 py-2 text-xs text-red-400 bg-red-400/10 border border-red-400/20 rounded-lg hover:bg-red-400/20 transition-all">Delete</button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}

          {view === 'add' && (
            <div className="space-y-5">
              <button onClick={() => setView('list')} className="text-white/50 hover:text-[#31b6ff] text-sm transition-colors flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
                Back to list
              </button>

              <div className="flex items-center justify-center py-6 bg-white/[0.02] border border-white/[0.06] rounded-xl">
                <div className="flex flex-col items-center gap-3">
                  <div
                    className="rounded-full transition-all duration-150"
                    style={{
                      backgroundColor: getColorHex(form.color),
                      width: `${Math.max(16, Math.min(56, 16 + form.scale * 40))}px`,
                      height: `${Math.max(16, Math.min(56, 16 + form.scale * 40))}px`,
                      boxShadow: `0 0 ${Math.max(8, form.scale * 24)}px ${getColorHex(form.color)}80`
                    }}
                  />
                  <div className="text-center">
                    <span className="text-white/70 text-sm">{selectedSprite?.name || 'Unknown'}</span>
                    <span className="text-white/30 text-xs block mt-0.5">Sprite #{form.sprite}</span>
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-white/60 text-sm mb-2">Blip Name</label>
                <input type="text" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="Enter name..." className="w-full px-4 py-3 bg-white/[0.04] border border-white/10 rounded-lg text-white placeholder-white/30 focus:border-[#E32AF1] focus:outline-none transition-colors" />
              </div>

              <div className="relative">
                <label className="block text-white/60 text-sm mb-2">Sprite (Icon)</label>
                <button
                  type="button"
                  onClick={() => setShowSpriteDropdown(!showSpriteDropdown)}
                  className="w-full px-4 py-3 bg-white/[0.04] border border-white/10 rounded-lg text-white text-left flex items-center justify-between focus:border-[#E32AF1] focus:outline-none transition-colors"
                >
                  <span>{selectedSprite ? `${selectedSprite.name} (${selectedSprite.id})` : 'Select sprite...'}</span>
                  <svg className={`w-4 h-4 transition-transform ${showSpriteDropdown ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
                </button>
                {showSpriteDropdown && (
                  <div className="absolute z-10 mt-2 w-full bg-[#1a1a24] border border-white/10 rounded-lg shadow-xl max-h-60 overflow-hidden">
                    <div className="sticky top-0 bg-[#1a1a24] p-2 border-b border-white/10">
                      <input
                        type="text"
                        value={spriteSearch}
                        onChange={e => setSpriteSearch(e.target.value)}
                        placeholder="Search sprites..."
                        className="w-full px-3 py-2 bg-white/[0.04] border border-white/10 rounded text-white text-sm placeholder-white/30 focus:border-[#E32AF1] focus:outline-none"
                        onClick={e => e.stopPropagation()}
                      />
                    </div>
                    <div className="overflow-y-auto max-h-48">
                      {filteredSprites.map(sprite => (
                        <button
                          key={sprite.id}
                          type="button"
                          onClick={() => {
                            setForm({ ...form, sprite: sprite.id });
                            setShowSpriteDropdown(false);
                            setSpriteSearch('');
                          }}
                          className={`w-full px-4 py-2 text-left text-sm hover:bg-white/[0.06] transition-colors ${form.sprite === sprite.id ? 'text-[#E32AF1] bg-[#E32AF1]/10' : 'text-white/80'}`}
                        >
                          {sprite.name} <span className="text-white/40">({sprite.id})</span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <div>
                <label className="block text-white/60 text-sm mb-2">Color</label>
                <div className="grid grid-cols-10 gap-1.5 max-h-48 overflow-y-auto pr-1">
                  {colors.map(c => (
                    <button key={c.id} onClick={() => setForm({ ...form, color: c.id })} className={`h-8 rounded border-2 transition-all ${form.color === c.id ? 'border-[#E32AF1] scale-110' : 'border-transparent'}`} style={{ backgroundColor: c.hex }} title={`${c.id}: ${c.name}`} />
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-white/60 text-sm mb-2">Scale: {form.scale.toFixed(1)}</label>
                <input type="range" min="0" max="1" step="0.1" value={form.scale} onChange={e => setForm({ ...form, scale: Math.max(0, Math.min(1, parseFloat(e.target.value))) })} className="w-full h-2 bg-white/10 rounded-lg appearance-none cursor-pointer accent-[#E32AF1]" />
              </div>

              <button onClick={handleCreate} disabled={!form.name.trim()} className="w-full py-3 bg-gradient-to-r from-[#E32AF1] to-[#c41ed6] text-white font-medium rounded-lg hover:shadow-[0_0_20px_rgba(227,42,241,0.4)] disabled:opacity-50 disabled:cursor-not-allowed transition-all">
                Create Blip
              </button>
            </div>
          )}

          {view === 'edit' && editingBlip && (
            <div className="space-y-5">
              <button onClick={() => { setView('list'); setEditingBlip(null); }} className="text-white/50 hover:text-[#31b6ff] text-sm transition-colors flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
                Back to list
              </button>

              <div className="p-3 bg-white/[0.02] border border-white/[0.06] rounded-lg">
                <span className="text-white/40 text-xs">Editing:</span>
                <span className="text-white ml-2">{editingBlip.name}</span>
                <span className="text-white/30 text-xs ml-2">(ID: {editingBlip.id})</span>
              </div>

              <div className="flex items-center justify-center py-6 bg-white/[0.02] border border-white/[0.06] rounded-xl">
                <div className="flex flex-col items-center gap-3">
                  <div
                    className="rounded-full transition-all duration-150"
                    style={{
                      backgroundColor: getColorHex(form.color),
                      width: `${Math.max(16, Math.min(56, 16 + form.scale * 40))}px`,
                      height: `${Math.max(16, Math.min(56, 16 + form.scale * 40))}px`,
                      boxShadow: `0 0 ${Math.max(8, form.scale * 24)}px ${getColorHex(form.color)}80`
                    }}
                  />
                  <div className="text-center">
                    <span className="text-white/70 text-sm">{selectedSprite?.name || 'Unknown'}</span>
                    <span className="text-white/30 text-xs block mt-0.5">Sprite #{form.sprite}</span>
                  </div>
                </div>
              </div>

              <div className="relative">
                <label className="block text-white/60 text-sm mb-2">Sprite (Icon)</label>
                <button
                  type="button"
                  onClick={() => setShowSpriteDropdown(!showSpriteDropdown)}
                  className="w-full px-4 py-3 bg-white/[0.04] border border-white/10 rounded-lg text-white text-left flex items-center justify-between focus:border-[#E32AF1] focus:outline-none transition-colors"
                >
                  <span>{selectedSprite ? `${selectedSprite.name} (${selectedSprite.id})` : 'Select sprite...'}</span>
                  <svg className={`w-4 h-4 transition-transform ${showSpriteDropdown ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
                </button>
                {showSpriteDropdown && (
                  <div className="absolute z-10 mt-2 w-full bg-[#1a1a24] border border-white/10 rounded-lg shadow-xl max-h-60 overflow-hidden">
                    <div className="sticky top-0 bg-[#1a1a24] p-2 border-b border-white/10">
                      <input
                        type="text"
                        value={spriteSearch}
                        onChange={e => setSpriteSearch(e.target.value)}
                        placeholder="Search sprites..."
                        className="w-full px-3 py-2 bg-white/[0.04] border border-white/10 rounded text-white text-sm placeholder-white/30 focus:border-[#E32AF1] focus:outline-none"
                        onClick={e => e.stopPropagation()}
                      />
                    </div>
                    <div className="overflow-y-auto max-h-48">
                      {filteredSprites.map(sprite => (
                        <button
                          key={sprite.id}
                          type="button"
                          onClick={() => {
                            setForm({ ...form, sprite: sprite.id });
                            setShowSpriteDropdown(false);
                            setSpriteSearch('');
                          }}
                          className={`w-full px-4 py-2 text-left text-sm hover:bg-white/[0.06] transition-colors ${form.sprite === sprite.id ? 'text-[#E32AF1] bg-[#E32AF1]/10' : 'text-white/80'}`}
                        >
                          {sprite.name} <span className="text-white/40">({sprite.id})</span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              <div>
                <label className="block text-white/60 text-sm mb-2">Color</label>
                <div className="grid grid-cols-10 gap-1.5 max-h-48 overflow-y-auto pr-1">
                  {colors.map(c => (
                    <button key={c.id} onClick={() => setForm({ ...form, color: c.id })} className={`h-8 rounded border-2 transition-all ${form.color === c.id ? 'border-[#E32AF1] scale-110' : 'border-transparent'}`} style={{ backgroundColor: c.hex }} title={`${c.id}: ${c.name}`} />
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-white/60 text-sm mb-2">Scale: {form.scale.toFixed(1)}</label>
                <input type="range" min="0" max="1" step="0.1" value={form.scale} onChange={e => setForm({ ...form, scale: Math.max(0, Math.min(1, parseFloat(e.target.value))) })} className="w-full h-2 bg-white/10 rounded-lg appearance-none cursor-pointer accent-[#E32AF1]" />
              </div>

              <button onClick={handleEdit} className="w-full py-3 bg-gradient-to-r from-[#31b6ff] to-[#2899d6] text-white font-medium rounded-lg hover:shadow-[0_0_20px_rgba(49,182,255,0.4)] transition-all">
                Save Changes
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
