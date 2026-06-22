<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\KategoriKegiatan\StoreKategoriKegiatanRequest;
use App\Http\Requests\KategoriKegiatan\UpdateKategoriKegiatanRequest;
use App\Http\Resources\KategoriKegiatanResource;
use App\Models\KategoriKegiatan;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class KategoriKegiatanController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse(
            'Data kategori kegiatan berhasil diambil',
            KategoriKegiatanResource::collection(KategoriKegiatan::latest()->get())
        );
    }

    public function store(StoreKategoriKegiatanRequest $request): JsonResponse
    {
        $kategori = KategoriKegiatan::create($request->validated());

        return $this->successResponse('Kategori kegiatan berhasil dibuat', new KategoriKegiatanResource($kategori), 201);
    }

    public function show(KategoriKegiatan $kategoriKegiatan): JsonResponse
    {
        return $this->successResponse(
            'Detail kategori kegiatan berhasil diambil',
            new KategoriKegiatanResource($kategoriKegiatan)
        );
    }

    public function update(UpdateKategoriKegiatanRequest $request, KategoriKegiatan $kategoriKegiatan): JsonResponse
    {
        $kategoriKegiatan->update($request->validated());

        return $this->successResponse(
            'Kategori kegiatan berhasil diperbarui',
            new KategoriKegiatanResource($kategoriKegiatan)
        );
    }

    public function destroy(KategoriKegiatan $kategoriKegiatan): JsonResponse
    {
        $kategoriKegiatan->delete();

        return $this->successResponse('Kategori kegiatan berhasil dihapus');
    }
}
