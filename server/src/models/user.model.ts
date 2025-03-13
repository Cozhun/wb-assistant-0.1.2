import { BaseModel } from '.';

export interface User {
  userId?: number;
  enterpriseId: number;
  email: string;
  passwordHash: string;
  firstName?: string;
  lastName?: string;
  phoneNumber?: string;
  isActive?: boolean;
  lastLoginAt?: Date;
  createdAt?: Date;
  twoFactorEnabled?: boolean;
  refreshToken?: string;
  refreshTokenExpiresAt?: Date;
}

export interface Role {
  roleId: number;
  roleName: string;
  description?: string;
  isSystem?: boolean;
}

export interface UserRole {
  userId: number;
  roleId: number;
}

export class UserModel extends BaseModel {
  // Получение пользователя по ID
  static async getById(userId: number): Promise<User | null> {
    const sql = `
      SELECT * FROM Users
      WHERE UserId = $1
    `;
    const result = await this.query<User>(sql, [userId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение пользователя по email и enterpriseId
  static async getByEmail(email: string, enterpriseId: number): Promise<User | null> {
    const sql = `
      SELECT * FROM Users
      WHERE Email = $1 AND EnterpriseId = $2
    `;
    const result = await this.query<User>(sql, [email, enterpriseId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех пользователей предприятия
  static async getByEnterpriseId(enterpriseId: number): Promise<User[]> {
    const sql = `
      SELECT * FROM Users
      WHERE EnterpriseId = $1
      ORDER BY UserId
    `;
    const result = await this.query<User>(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание нового пользователя
  static async create(user: User): Promise<User> {
    const sql = `
      INSERT INTO Users (
        EnterpriseId, Email, PasswordHash, FirstName, LastName,
        PhoneNumber, IsActive, TwoFactorEnabled
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8
      ) RETURNING *
    `;
    const result = await this.query<User>(sql, [
      user.enterpriseId,
      user.email,
      user.passwordHash,
      user.firstName || null,
      user.lastName || null,
      user.phoneNumber || null,
      user.isActive === undefined ? true : user.isActive,
      user.twoFactorEnabled || false
    ]);
    return result.rows[0];
  }

  // Обновление пользователя
  static async update(userId: number, user: Partial<User>): Promise<User | null> {
    const fields: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (user.email !== undefined) {
      fields.push(`Email = $${paramIndex++}`);
      values.push(user.email);
    }
    if (user.passwordHash !== undefined) {
      fields.push(`PasswordHash = $${paramIndex++}`);
      values.push(user.passwordHash);
    }
    if (user.firstName !== undefined) {
      fields.push(`FirstName = $${paramIndex++}`);
      values.push(user.firstName);
    }
    if (user.lastName !== undefined) {
      fields.push(`LastName = $${paramIndex++}`);
      values.push(user.lastName);
    }
    if (user.phoneNumber !== undefined) {
      fields.push(`PhoneNumber = $${paramIndex++}`);
      values.push(user.phoneNumber);
    }
    if (user.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(user.isActive);
    }
    if (user.lastLoginAt !== undefined) {
      fields.push(`LastLoginAt = $${paramIndex++}`);
      values.push(user.lastLoginAt);
    }
    if (user.twoFactorEnabled !== undefined) {
      fields.push(`TwoFactorEnabled = $${paramIndex++}`);
      values.push(user.twoFactorEnabled);
    }
    if (user.refreshToken !== undefined) {
      fields.push(`RefreshToken = $${paramIndex++}`);
      values.push(user.refreshToken);
    }
    if (user.refreshTokenExpiresAt !== undefined) {
      fields.push(`RefreshTokenExpiresAt = $${paramIndex++}`);
      values.push(user.refreshTokenExpiresAt);
    }

    if (fields.length === 0) {
      return this.getById(userId);
    }

    const sql = `
      UPDATE Users
      SET ${fields.join(', ')}
      WHERE UserId = $${paramIndex}
      RETURNING *
    `;
    values.push(userId);

    const result = await this.query<User>(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Обновление времени последнего входа
  static async updateLastLogin(userId: number): Promise<boolean> {
    const sql = `
      UPDATE Users
      SET LastLoginAt = CURRENT_TIMESTAMP
      WHERE UserId = $1
    `;
    const result = await this.query(sql, [userId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Удаление пользователя (логическое)
  static async delete(userId: number): Promise<boolean> {
    const sql = `
      UPDATE Users
      SET IsActive = FALSE
      WHERE UserId = $1
    `;
    const result = await this.query(sql, [userId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Получение всех ролей
  static async getAllRoles(): Promise<Role[]> {
    const sql = `
      SELECT * FROM Roles
      ORDER BY RoleId
    `;
    const result = await this.query<Role>(sql);
    return result.rows;
  }

  // Получение ролей пользователя
  static async getUserRoles(userId: number): Promise<Role[]> {
    const sql = `
      SELECT r.*
      FROM Roles r
      JOIN UserRoles ur ON r.RoleId = ur.RoleId
      WHERE ur.UserId = $1
    `;
    const result = await this.query<Role>(sql, [userId]);
    return result.rows;
  }

  // Добавление роли пользователю
  static async addUserRole(userId: number, roleId: number): Promise<boolean> {
    const sql = `
      INSERT INTO UserRoles (UserId, RoleId)
      VALUES ($1, $2)
      ON CONFLICT (UserId, RoleId) DO NOTHING
    `;
    const result = await this.query(sql, [userId, roleId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Удаление роли у пользователя
  static async removeUserRole(userId: number, roleId: number): Promise<boolean> {
    const sql = `
      DELETE FROM UserRoles
      WHERE UserId = $1 AND RoleId = $2
    `;
    const result = await this.query(sql, [userId, roleId]);
    return result.rowCount ? result.rowCount > 0 : false;
  }

  // Проверка, имеет ли пользователь роль
  static async hasRole(userId: number, roleId: number): Promise<boolean> {
    const sql = `
      SELECT 1 FROM UserRoles
      WHERE UserId = $1 AND RoleId = $2
    `;
    const result = await this.query(sql, [userId, roleId]);
    return result.rows.length > 0;
  }

  // Получение всех активных пользователей с определенной ролью
  static async getUsersByRole(enterpriseId: number, roleId: number): Promise<User[]> {
    const sql = `
      SELECT u.*
      FROM Users u
      JOIN UserRoles ur ON u.UserId = ur.UserId
      WHERE u.EnterpriseId = $1 AND ur.RoleId = $2 AND u.IsActive = TRUE
    `;
    const result = await this.query<User>(sql, [enterpriseId, roleId]);
    return result.rows;
  }
} 