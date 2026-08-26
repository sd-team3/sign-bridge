export class JamoApiClient {
  constructor(baseUrl = "") {
    this.baseUrl = baseUrl.replace(/\/$/, "");
  }

  async _postJson(path, body) {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok) {
      const err = new Error(data.detail || `요청 실패: ${path}`);
      err.status = res.status;
      err.body = data;
      throw err;
    }
    return data;
  }

  async _get(path) {
    const res = await fetch(`${this.baseUrl}${path}`);
    const data = await res.json();
    if (!res.ok) {
      const err = new Error(data.detail || `요청 실패: ${path}`);
      err.status = res.status;
      err.body = data;
      throw err;
    }
    return data;
  }

  health() {
    return this._get("/health");
  }

  getLabels() {
    return this._get("/labels");
  }

  predict(landmarks, mirror = false) {
    return this._postJson("/predict", { landmarks, mirror });
  }

  coach(landmarks, label, mirror = false) {
    return this._postJson("/coach", { landmarks, label, mirror });
  }

  collect(label, frames, mirror = false, collector = "unknown") {
    return this._postJson("/collect", { label, mirror, frames, collector });
  }

  getDatasetStats() {
    return this._get("/dataset/stats");
  }

  mergeDataset() {
    return this._postJson("/dataset/merge", {});
  }

  trainModel() {
    return this._postJson("/model/train", {});
  }
}
