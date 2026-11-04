// Pure toolbar arrangement helpers. Persistent preferences use stable action IDs,
// not indices, so adding/removing configured actions does not corrupt the order.
// Normalize persisted/shared input without mutating it. All mutators below
// return fresh arrays so callers can safely publish them through setShared.
export function toolbarPreferences(value) {
  const ids = (items) =>
    Array.isArray(items) ? [...new Set(items.filter((id) => typeof id === "string"))] : [];
  return { hidden: ids(value?.hidden), pinned: ids(value?.pinned), order: ids(value?.order) };
}

export function arrangedActions(entries, preferences) {
  const { order } = toolbarPreferences(preferences);
  const rank = new Map(order.map((id, index) => [id, index]));
  // Stable sorting leaves newly configured, unranked entries in input order.
  return entries
    .slice()
    .sort((a, b) => (rank.get(a.id) ?? Infinity) - (rank.get(b.id) ?? Infinity));
}

export function toolbarPartition(entries, preferences, limit) {
  const saved = toolbarPreferences(preferences);
  const visible = arrangedActions(entries, saved)
    .filter(
      (entry) =>
        !saved.hidden.includes(entry.id) &&
        (entry.overflow !== true || saved.pinned.includes(entry.id)),
    )
    .slice(0, Math.max(0, limit));
  // Overflow is the complement, not just the explicitly hidden IDs. This
  // keeps actions recoverable when hidden by configuration or a narrow window.
  const visibleIDs = new Set(visible.map((entry) => entry.id));
  const overflow = entries
    .filter((entry) => !visibleIDs.has(entry.id))
    .sort(
      (a, b) =>
        String(a.label ?? a.id).localeCompare(String(b.label ?? b.id), undefined, {
          sensitivity: "base",
        }) || a.id.localeCompare(b.id),
    );
  return { visible, overflow };
}

export function hideToolbarAction(preferences, id) {
  const saved = toolbarPreferences(preferences);
  return {
    ...saved,
    hidden: [...new Set([...saved.hidden, id])],
    pinned: saved.pinned.filter((item) => item !== id),
  };
}

/** Move an action to an insertion boundary, or the front when using Pin. */
export function placeToolbarAction(entries, preferences, id, target = null, after = false) {
  const saved = toolbarPreferences(preferences);
  if (target === id)
    return {
      ...saved,
      hidden: saved.hidden.filter((item) => item !== id),
      pinned: [...new Set([...saved.pinned, id])],
    };
  const order = arrangedActions(entries, saved)
    .map((entry) => entry.id)
    .filter((item) => item !== id);
  const index = target ? order.indexOf(target) : 0;
  order.splice(index < 0 ? order.length : index + (target && after ? 1 : 0), 0, id);
  return {
    hidden: saved.hidden.filter((item) => item !== id),
    pinned: [...new Set([...saved.pinned, id])],
    order,
  };
}

/** Translate a before/after boundary into Herdr's one-based tab.move index. */
export function tabMoveIndex(tabs, sourceID, targetID, after) {
  const from = tabs.findIndex((tab) => tab.id === sourceID);
  const target = tabs.findIndex((tab) => tab.id === targetID);
  if (from < 0 || target < 0) return null;
  const boundary = target + (after ? 1 : 0);
  // Removing a source to the left shifts the insertion boundary one slot back.
  const destination = boundary - (from < boundary ? 1 : 0);
  return destination === from ? null : destination + 1;
}
