import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import type { Role, SafeUser, User } from "./types.js";

const secret = process.env.JWT_SECRET || "nsd-demo-secret-change-in-production";

export interface AuthPayload {
  sub: string;
  role: Role;
  email: string;
}

export interface AuthenticatedRequest extends Request {
  auth?: AuthPayload;
}

export function safeUser(user: User): SafeUser {
  const { passwordHash: _passwordHash, ...safe } = user;
  return safe;
}

export function signToken(user: User): string {
  return jwt.sign(
    { role: user.role, email: user.email },
    secret,
    { subject: user.id, expiresIn: "24h" },
  );
}

export function authenticate(
  request: AuthenticatedRequest,
  response: Response,
  next: NextFunction,
): void {
  const header = request.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    response.status(401).json({ message: "Sesi login diperlukan." });
    return;
  }

  try {
    request.auth = jwt.verify(header.slice(7), secret) as AuthPayload;
    next();
  } catch {
    response.status(401).json({ message: "Sesi tidak valid atau sudah berakhir." });
  }
}

export function allowRoles(...roles: Role[]) {
  return (
    request: AuthenticatedRequest,
    response: Response,
    next: NextFunction,
  ): void => {
    if (!request.auth || !roles.includes(request.auth.role)) {
      response.status(403).json({ message: "Anda tidak memiliki akses ke fitur ini." });
      return;
    }
    next();
  };
}

