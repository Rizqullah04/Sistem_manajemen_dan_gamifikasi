<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'status' => false,
                'message' => 'Unauthenticated.',
                'data' => (object) [],
            ], 401);
        }

        if (! in_array($user->role, $roles, true)) {
            return response()->json([
                'status' => false,
                'message' => 'Anda tidak memiliki akses ke resource ini.',
                'data' => (object) [],
            ], 403);
        }

        return $next($request);
    }
}
